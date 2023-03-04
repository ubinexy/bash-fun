# read from stdin
# expand json into a list of key, value pairs in seperate lines
expand() {
    # convert stdin to tup argument
    if [[ $# -eq 0 ]]; then
        cat - | jq -r 'to_entries[] | "(.\(.key),\(.value))"' | map 'expand'
    # argument is a tup
    elif [[ $# -eq 1 ]]; then
        local key=$(echo $@ | tupl)
        local value=$(echo $@ | strip '(' | stripl "$key" | stripl ',' | stripr ')') 
        expand "" $key $value
    else
        local key=$1$2
        local value=$3
        if [[ $value == '['* ]]; then
            # value is array
            local i=0
            for v in $(echo $value | jq -r '.[]'); do
                expand $key "["$i"]" "$v"
                i=$((i+1))
            done
        elif [[ $value == '{'* ]]; then
            # value is object 
            echo "$value" | jq --arg PREFIX "$key" -r 'to_entries[] | "(\($PREFIX).\(.key),\(.value))"' | map 'expand'
        else
            # value is number or string
            tup $key $value
        fi
    fi
}

# to group elements by a function
# each group is in separated lines and each element is in a group is separated by a space
groupby() {
    local func="$@"
    local separator='='

    # to append an element to a list
    group() {
        local element=$1
        local groups=$(echo -e "$@" | stripl "$element" | tr "$separator" '\n')
        local lastGroup=$(echo -e "$groups" | tail -n 1)
        local restGroups="$(echo -e "$groups" | stripr "$lastGroup")"

        [[ ! -z $restGroups ]] && restGroups="$restGroups""\n" || false

        # if the element matches the last group, append the element to the last group
        if [[ $(echo "$lastGroup" | $func)" " == $(echo "$element" | $func)* ]]; then
            echo -e "$restGroups"$(list $lastGroup | append $element | unlist) | tr '\n' "$separator"
        else
        # otherwise, append the element to the list as a new group
            echo -e "$groups""\n""$element" | tr '\n' "$separator"
        fi
    }

    cat - | sort \
          | foldl lambda groups ele . 'group $ele $groups' \
          | stripr "$separator" \
          | tr "$separator" '\n'
}

# quote a string if it is not a number or boolean or null or object
to_str() {
    if [[ $# -eq 0 ]]; then # from stdin
        local value=$(cat -)
    else # from arguments            
        local value=$1
    fi

    if [[ $value != 'true' && $value != 'false' && $value != 'null' && $value != '{'*'}' ]]; then
        if [[ $value =~ ^[+-]?[0-9]*\.?[0-9]([eE][+-]?[0-9]+)?$ ]]; then
            : #do nothing
        else
            value="\"$value\""
        fi
    fi
    echo $value
}

# to convert a key, value pair into json entry
# key is a dot-separated string to indicate the path to the value.
_entry() {
    # from stdin
    if [[ $@ == '('* ]]; then
        local key=$(echo "$@" | tupl)
        local val=$(echo "$@" | stripl '(' | stripl "$key" | stripl ',' | stripr ')') 
        _entry $key $val
    # from arguments
    elif [[ $# -eq 2 ]]; then
        local key=$(echo $1 | stripl '.')
        local value=$2
        if [[ $value == '['*']' && $value != '[{'*'}]' ]]; then
            value=$(echo $value | stripl '[' | stripr ']' | tr ',' '\n' | map 'to_str' | join ',' '[' ']' )
        else 
            value=$(echo $value | to_str)
        fi
        if [[ $key != *.* ]]; then
            ret \"$key\"":"$value
        else
            local head=$(echo $key | cut -d'.' -f1)
            local rest='.'$(echo $key | cut -d'.' -f2-)
            ret \"$head\"":{"$(_entry $rest $value)"}"
        fi
    fi
}

# to combine a list of key, value pairs into a json object.
combine() {
    prefix() {
        ret $(echo $1 | tupl | cut -d'.' -f2 | sed -E 's/\[[0-9]+\]$//g')
    }

    remove_prefix() {
        local pre=$(prefix $@)
        if [[ $pre == *'['*']'* ]]; then
            pre=$(echo $pre | sed -e 's/\]/\\]/g' -e 's/\[/\\[/g')
        fi
        ret $(echo $1 | sed -e "s/(\.$pre/(/g")
    }

    to_entry() {
        local pre=$(prefix $@)
        # convert space separated tups to json entry
        if [[ $# != 1 ]]; then
            local entries=$(echo "$@" | tr ' ' $'\n' | map 'remove_prefix' | map 'to_entry' | join ',' '{' '}')
            # if prefix is same and entries is empty, it is an array
            if [[ $entries == '{}' ]]; then
                entries=$(echo "$@" | tr ' ' $'\n' | map 'tupr' | join ',' '[' ']')
            fi
            _entry $pre $entries
        # convert a single tup to json entry
        elif [[ "$@" == "(."$pre* ]]; then
            _entry $@
        fi
    }

    cat - | groupby lambda a . 'prefix $a' \
          | map 'to_entry' \
          | join ',' '{' '}'
}
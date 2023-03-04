. ../src/expand.sh

testGroupbyFunction() {
    local input=$(cat <<EOF
(.name,bob)
(.age,18)
EOF
)
    local expected=$(cat <<EOF
(.age,18)
(.name,bob)
EOF
)
    # When
    local result=$(echo "$input" | groupby lambda x . 'echo $x')
    # Then
    assertEquals "$expected" "$result"
}

testGroupbyFunction() {
    local input=$(cat <<EOF
(.name,bob)
(.age,18)
EOF
)
    local expected=$(cat <<EOF
(.age,18) (.name,bob)
EOF
)
    # When
    local result=$(echo "$input" | groupby lambda x . 'echo "x"')
    # Then
    assertEquals "$expected" "$result"
}

testGroupbyFunction() {
    prefix() {
        echo $1 | tupl | cut -d'.' -f2 | sed -E 's/\[[0-9]+\]$//g'
    }

    local input=$(cat <<EOF
(.hobbies[0],reading)
(.hobbies[1],writing)
EOF
)

    local expected=$(cat <<EOF
(.hobbies[0],reading) (.hobbies[1],writing)
EOF
)
    # When
    local result=$(echo "$input" | groupby 'prefix')
    # Then
    assertEquals "$expected" "$result"
}

. ./shunit2-init.sh
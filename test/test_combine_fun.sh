. ../src/expand.sh

testCombineFunction() {
    local expected='{"age":18,"name":"bob"}'
    local input=$(cat <<EOF
(.name,bob)
(.age,18)
EOF
)
    # When
    local result=$(echo "$input" | combine)
    # Then
    assertEquals "$expected" "$result"
}

testCombineFunction2() {
    local expected='{"age":18,"name":{"firstName":"bob","lastName":"H"}}'
    local input=$(cat <<EOF
(.name.firstName,bob)
(.name.lastName,H)
(.age,18)
EOF
)    
    # When
    local result=$(echo "$input" | combine)
    # Then
    assertEquals "$expected" "$result"
}

testCombineFunction3() {
    local expected='{"hobbies":["reading","writing","coding"]}'
    local input=$(cat <<EOF
(.hobbies[0],reading)
(.hobbies[1],writing)
(.hobbies[2],coding)
EOF
)
    # When
    local result=$(echo "$input" | combine)
    # Then
    assertEquals "$expected" "$result"
}

. ./shunit2-init.sh
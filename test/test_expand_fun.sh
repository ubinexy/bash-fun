. ../src/expand.sh

testExpandFunction() {
    local input='{"name":"bob","age":18}'
    local expected=$(cat <<EOF
(.name,bob)
(.age,18)
EOF
)
    # When
    local result=$(echo $input | expand)
    # Then
    assertEquals "$expected" "$result"
}

testDeepExpandFunction() {
    local json='{"name":{"firstName":"bob", "lastName":"H"},"age":18}'
    local expected=$(cat <<EOF
(.name.firstName,bob)
(.name.lastName,H)
(.age,18)
EOF
)
    # When
    local result=$(echo $json | expand)
    # Then
    assertEquals "$expected" "$result"
}


testExpandFunction() {
    local json='{"hobbies":["reading","writing","coding"]}'
    local expected=$(cat <<EOF
(.hobbies[0],reading)
(.hobbies[1],writing)
(.hobbies[2],coding)
EOF
)
    # When
    local result=$(echo $json | expand)
    # Then
    assertEquals "$expected" "$result"
}

. ./shunit2-init.sh
#!/bin/bash

# Start Sonar
./bin/run.sh &

BASE_URL=http://127.0.0.1:9000

# Access SonarQube api with admin credentials
function curlAdmin {
    curl -v -u admin:admin $@
}

# Check is SonarQube is running
function isUp {
    curl -s -u admin:admin -f "$BASE_URL/api/system/info"
}

# Create a new SonarQube profile with custom activated rules, inheritance and set as default
# parameters
# $1 = profile name (the filename must match the profile name)
# $2 = parent profile name
# $3 = language (cs | java | py | js | ts | web | ...)
# $4 = comma separated list of rules (keys) to be activated in the profile (apart from the standard parent profile rules)
function createProfile {
    local profileName=$1
    local baseProfileName=$2
    local language=$3
    local rules=$4
    echo $rules
    local ruleList=$(echo $rules | tr "," "\n")

    # create profile
    curlAdmin -X POST "$BASE_URL/api/qualityprofiles/create?name=$profileName&language=$language"
    
    # set parent
    curlAdmin -X POST --data "qualityProfile=$1&parentQualityProfile=$2&language=$3" "$BASE_URL/api/qualityprofiles/change_parent"

    # retrieve profile key
    json=`curl $BASE_URL/api/qualityprofiles/search?qualityProfile=$profileName`
    key=$(echo $json | grep -Eo '"key":"([-A-Z0-9a-z-]*)"' | cut -d: -f2 | sed -r 's/"//g')
    echo "key=[$key]"
    
    # activate rules in new profile
    for rule in $ruleList
    do
        curlAdmin -X POST "$BASE_URL/api/qualityprofiles/activate_rule?key=$key&rule=$rule"
    done

    # set profile as default
    curlAdmin -X POST "$BASE_URL/api/qualityprofiles/set_default?profileName=$1&language=$3"
}

# Wait for server to be up
PING=`isUp`
while [ -z "$PING" ]
do
    sleep 5
    PING=`isUp`
done

createProfile "ictu-cs-profile-6.5" "Sonar%20way" "cs" "common-cs:DuplicatedBlocks,csharpsquid:S104,csharpsquid:S134,csharpsquid:S1067,csharpsquid:S1541"
createProfile "ictu-java-profile-4.14" "Sonar%20way" "java" "squid:MethodCyclomaticComplexity,squid:NoSonar,squid:S1067,squid:S109"
createProfile "ictu-py-profile-6.5" "Sonar%20way" "py" "common-py:DuplicatedBlocks,python:S104,python:S134"
createProfile "ictu-js-profile-3.2" "Sonar%20way%20Recommended" "js" "javascript:FunctionComplexity,javascript:NestedIfDepth,javascript:S1067,javascript:S2228"
createProfile "ictu-ts-profile-1.1" "Sonar%20way%20recommended" "ts" "common-ts:DuplicatedBlocks,typescript:S109,typescript:S104,typescript:S2228"
createProfile "ictu-web-profile-2.5" "Sonar%20way" "web" "common-web:DuplicatedBlocks,Web:ComplexityCheck,Web:LongJavaScriptCheck,Web:S1443"

# Manually install the vbnet plugin
# Adding it to plugin-list is not working (causint SQ initilization error "There is already a quality profile with name 'Sonar way' for language 'vb'")
curlAdmin -X POST "$BASE_URL/api/plugins/install?key=vbnet"
curlAdmin -X POST "$BASE_URL/api/system/restart"

# Wait for server to be up
while [ -z "$PING" ]
do
    sleep 5
    PING=`isUp`
done
createProfile "ictu-vb-profile-4.0" "Sonar%20way" "vbnet" "common-web:DuplicatedBlocks,Web:ComplexityCheck,Web:LongJavaScriptCheck,Web:S1443"

wait
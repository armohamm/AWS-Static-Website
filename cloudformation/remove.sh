#!/bin/sh

# Paramters
parameters="parameters.json"
name=`jq -r '.[] | select(.ParameterKey=="Name") | .ParameterValue' $parameters`
profile=${1:-default}

echo "Deleting Stack: $name"
aws cloudformation update-termination-protection \
    --no-enable-termination-protection \
    --stack-name $name \
    --profile $profile
aws cloudformation delete-stack \
    --stack-name $name \
    --profile $profile
aws cloudformation wait stack-delete-complete \
    --stack-name $name \
    --profile $profile

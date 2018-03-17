#!/bin/sh

# Paramters
capabilities="CAPABILITY_IAM"
parameters="parameters.json"
name=`jq -r '.[] | select(.ParameterKey=="Name") | .ParameterValue' $parameters`
profile=${1:-default}
template="template.yml"

# Check if stack exists
aws cloudformation list-stack-resources \
    --profile $profile \
    --stack-name $name &> /dev/null

if [ $? -eq 0 ]; then
# Update the existing stack
    echo "Updating Stack: $name"
    aws cloudformation update-stack \
        --capabilities CAPABILITY_IAM \
        --parameters "file://$parameters" \
        --profile $profile \
        --stack-name $name \
        --tags "Key=Name,Value=$name" \
        --template-body "file://$template"
    aws cloudformation wait stack-update-complete \
        --profile $profile \
        --stack-name $name
else
# create a new stack
    echo "Creating Stack: $name"
    aws cloudformation create-stack \
        --capabilities $capabilities \
        --enable-termination-protection \
        --parameters "file://$parameters" \
        --profile $profile \
        --stack-name $name \
        --tags "Key=Name,Value=$name" \
        --template-body "file://$template"
    aws cloudformation wait stack-create-complete \
        --profile $profile \
        --stack-name $name
fi

aws cloudformation wait stack-exists \
    --stack-name $name \
    --profile $profile

repo=`aws cloudformation describe-stacks \
    --stack-name $name \
    --query 'Stacks[0].Outputs[?OutputKey==\`RepoHttpURL\`].OutputValue' \
    --output text \
    --profile $profile`

echo $repo
git remote set-url origin $repo

zone=`aws cloudformation describe-stacks \
    --stack-name $name \
    --query 'Stacks[0].Outputs[?OutputKey==\`HostedZoneId\`].OutputValue' \
    --output text \
    --profile $profile`
domain=`aws cloudformation describe-stacks \
    --stack-name $name \
    --query 'Stacks[0].Outputs[?OutputKey==\`Domain\`].OutputValue' \
    --output text \
    --profile $profile`
ns1=`aws route53 get-hosted-zone \
    --id $zone \
    --query 'DelegationSet.NameServers[0]' \
    --output text \
    --profile $profile`
ns2=`aws route53 get-hosted-zone \
    --id $zone \
    --query 'DelegationSet.NameServers[1]' \
    --output text \
    --profile $profile`
ns3=`aws route53 get-hosted-zone \
    --id $zone \
    --query 'DelegationSet.NameServers[2]' \
    --output text \
    --profile $profile`
ns4=`aws route53 get-hosted-zone \
    --id $zone \
    --query 'DelegationSet.NameServers[3]' \
    --output text \
    --profile $profile`

aws route53domains update-domain-nameservers --domain-name $domain --nameservers "Name=$ns1" "Name=$ns2" "Name=$ns3" "Name=$ns4"

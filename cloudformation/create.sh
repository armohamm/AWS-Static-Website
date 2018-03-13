profile=${1:-default}
template="file://template.yml"
parameters="file://parameters.json"
name=${PWD%/*}
name=${name##*/}
name="${name//./}"
name=`echo $name | tr '[:lower:]' '[:upper:]'`
echo Stack Name: $name

STACK=`aws cloudformation list-stack-resources \
    --stack-name $name \
    --profile $profile &> /dev/null`
if [ $? -eq 0 ]; then
    echo Updating Stack
    aws cloudformation update-stack \
        --template-body $template \
        --stack-name $name \
        --parameters $parameters \
        --capabilities CAPABILITY_IAM \
        --profile $profile
    aws cloudformation wait stack-update-complete \
        --stack-name $name \
        --profile $profile

else
    echo Creating Stack
    aws cloudformation create-stack \
        --template-body $template \
        --stack-name $name \
        --parameters $parameters \
        --capabilities CAPABILITY_IAM \
        --enable-termination-protection \
        --profile $profile

    aws cloudformation wait stack-create-complete \
        --stack-name $name \
        --profile $profile

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

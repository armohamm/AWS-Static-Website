profile=${1:-default}
name=${PWD%/*}
name=${name##*/}
name="${name//./}"
name=`echo $name | tr '[:lower:]' '[:upper:]'`
echo Stack Name: $name
echo Deleting Stack
aws cloudformation update-termination-protection --no-enable-termination-protection --stack-name $name --profile $profile
aws cloudformation delete-stack --stack-name $name --profile $profile

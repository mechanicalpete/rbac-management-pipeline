#!/bin/bash
set -e
reset

# Update to use a different AWS profile
PROFILE=@@aws-profile@@
REGION=@@aws-region@@
STACK_NAME=@@camel-case-name@@-Inception

echo "Create the initial CloudFormation Stack"
aws --region ${REGION} --profile ${PROFILE} cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://pipeline/aws_seed.yml --parameters file://pipeline/aws_seed-cli-parameters.json --capabilities "CAPABILITY_NAMED_IAM"
echo "Waiting for the CloudFormation stack to finish being created."
aws --region ${REGION} --profile ${PROFILE} cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
# Print out all the CloudFormation outputs.
aws --region ${REGION} --profile ${PROFILE} cloudformation describe-stacks --stack-name ${STACK_NAME} --output table --query "Stacks[0].Outputs"

export CODECOMMIT_REPO=`aws --region ${REGION} --profile ${PROFILE} cloudformation describe-stacks --stack-name ${STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='CodeCommitRepositoryCloneUrlHttp'].OutputValue"`

echo "Initialising Git repository"
git init
echo "Adding the newly created CodeCommit repository as origin"
git remote add origin ${CODECOMMIT_REPO}
echo "Adding all files"
git add .
echo "CodeCommitting files"
git commit -m "Initial commit"
echo "Pushing to CodeCommit"
git push --set-upstream origin master

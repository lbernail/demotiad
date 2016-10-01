#!/bin/bash
set -e

if [ -z $STATE_BUCKET -o -z $BLUE_STATE_KEY -o -z $GREEN_STATE_KEY -o -z $APP_DIR -o -z $REPO_NAME]
then
    echo 'No parameters'
    exit 0
fi

COMMIT=${TRAVIS_COMMIT:-'unknown'}
SHORT_COMMIT=${COMMIT:0:7}

ACCOUNT=aws sts get-caller-identity --query 'Account' --output text

echo "Building image"
docker build -t $REPO_NAME:$SHORT_COMMIT $APP_DIR

echo "Tagging image"
docker tag $REPO_NAME:$SHORT_COMMIT $REPO_NAME:latest
docker tag $REPO_NAME:$SHORT_COMMIT ${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${SHORT_COMMIT}
docker tag $REPO_NAME:$SHORT_COMMIT ${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:latest

echo "Logging to ECR"
$(aws ecr login)

echo "Pushing image"
docker push ${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${SHORT_COMMIT}
docker push ${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:latest

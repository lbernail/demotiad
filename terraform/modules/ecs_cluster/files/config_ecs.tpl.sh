#!/usr/bin/env bash
set -e

cluster=${TF_ECS_CLUSTER}
tasks=${TF_ALL_NODES_TASKS}

echo ECS_CLUSTER=$cluster >> /etc/ecs/ecs.config
start ecs

yum install -y aws-cli jq
instance_arn=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $NF}' )
az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$${az:0:$${#az} - 1}

for task in $tasks
do
    aws ecs start-task --cluster $cluster --task-definition $task --container-instances $instance_arn --region $region
done

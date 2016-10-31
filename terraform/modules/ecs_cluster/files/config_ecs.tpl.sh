#!/usr/bin/env bash
set -e
set -x

cluster=${TF_ECS_CLUSTER}
tasks="${TF_ALL_NODES_TASKS}"
efs_id="${TF_EFS_ID}"
efs_mount_point="${TF_EFS_MOUNT_POINT}"

echo "Installing packages"
yum install -y aws-cli jq nfs-utils
mkdir -p $efs_mount_point

az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$${az:0:$${#az} - 1}

echo "Mounting EFS"
address="$${az}.$${efs_id}.efs.$${region}.amazonaws.com"

echo "Waiting for resolution"
while ! getent hosts $address
do
    sleep 5
done
echo "$${address}:/ $${efs_mount_point} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab
mount /mnt/efs


# We need to restart the docker daemon to make it see the mount point
echo "Retarting docker and ecs"
echo ECS_CLUSTER=$cluster >> /etc/ecs/ecs.config
service docker restart
start ecs

instance_arn=""
echo "Waiting for ecs to be up and retrieving instance arn"
while [ -z "$instance_arn" ]
do
    instance_arn=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $NF}' ) 
    sleep 1
    date
done

echo "Starting configured tasks"
for task in $tasks
do
    aws ecs start-task --cluster $cluster --task-definition $task --container-instances $instance_arn --region $region
    sleep 5
done

#!/usr/bin/env bash
set -e

CLUSTER=${TF_ECS_CLUSTER}

echo ECS_CLUSTER=$CLUSTER >> /etc/ecs/ecs.config

variable "region" {
  type = "string"
}

variable "state_bucket" {
  type = "string"
}

variable "ecs_state_key" {
  type = "string"
}

variable "vpc_state_key" {
  type = "string"
}

variable "bridge_ip" {
  type = "string"
  default = "172.17.0.1"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ecs" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.ecs_state_key}"
    region = "${var.region}"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.vpc_state_key}"
    region = "${var.region}"
  }
}

data "template_file" "redis" {
  template = "${file("${path.module}/files/redis.tpl.json")}"

  vars {
      TF_REGION = "${var.region}"
      TF_LOG_GROUP = "${data.terraform_remote_state.ecs.log_group}"
  }
}

resource "aws_ecs_task_definition" "redis" {
  family = "redis"
  container_definitions = "${data.template_file.redis.rendered}"
}

resource "aws_ecs_service" "redis" {
  name = "redis"
  cluster = "${data.terraform_remote_state.ecs.cluster}"
  task_definition = "${aws_ecs_task_definition.redis.arn}"
  desired_count = 1
}


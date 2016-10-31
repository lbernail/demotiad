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

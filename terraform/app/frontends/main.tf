variable "region" {
  type = "string"
}

variable "state_bucket" {
  type = "string"
}

variable "ecs_state_key" {
  type = "string"
}

variable "voteapp_repo" {
  type = "string"
  default = "demotiad/vote"
}

variable "voteapp_tag" {
  type = "string"
  default = "latest"
}

variable "voteapp_count" {
  type = "string"
  default = "2"
}

variable "color" {
   type = "string"
}

variable "bridge_ip" {
  type = "string"
  default = "172.17.0.1"
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

data "template_file" "voteapp" {
  template = "${file("${path.module}/files/voteapp.tpl.json")}"

  vars {
      TF_ACCOUNT="${data.aws_caller_identity.current.account_id}",
      TF_REGION="${var.region}"
      TF_REPO="${var.voteapp_repo}"
      TF_TAG="${var.voteapp_tag}"
      TF_BRIDGE_IP="${var.bridge_ip}"
      TF_COLOR="${var.color}"
  }
}

resource "aws_ecs_task_definition" "voteapp" {
  family = "voteapp${var.color}"
  container_definitions = "${data.template_file.voteapp.rendered}"
}

resource "aws_ecs_service" "voteapp" {
  name = "voteapp${var.color}"
  cluster = "${data.terraform_remote_state.ecs.cluster}"
  task_definition = "${aws_ecs_task_definition.voteapp.arn}"
  desired_count = "${var.voteapp_count}"
}

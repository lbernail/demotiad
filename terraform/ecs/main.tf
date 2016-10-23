variable "region" {
  type = "string"
}

variable "state_bucket" {
  type = "string"
}

variable "vpc_state_key" {
  type = "string"
}

variable "consul_state_key" {
  type = "string"
}

variable "key_name" {
  type = "string"
}

variable "ecs_type" {
  type = "string"
  default = "t2.small"
}


provider "aws" {
  region = "${var.region}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.vpc_state_key}"
    region = "${var.region}"
  }
}

data "terraform_remote_state" "consul" {
  backend = "s3"

  config {
    bucket = "${var.state_bucket}"
    key    = "${var.consul_state_key}"
    region = "${var.region}"
  }
}

module ecs_cluster {
  source = "../modules/ecs_cluster"  

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}" 
  ecs_server_type = "${var.ecs_type}"

  sg_list = "${list(data.terraform_remote_state.vpc.sg_ssh,data.terraform_remote_state.consul.sg_consul_server)}"
  subnets = "${data.terraform_remote_state.vpc.private_subnets}"
  ecs_key = "${var.key_name}" 

  all_nodes_tasks = [ "${aws_ecs_task_definition.consul.family}","${aws_ecs_task_definition.registrator.family}","${aws_ecs_task_definition.cadvisor.family}" ]

  sg_admin = "${data.terraform_remote_state.vpc.sg_admin}"
  admin_ports = [ "8080" ]
  external_ports = []

  private_host_zone = "${data.terraform_remote_state.vpc.private_host_zone}"
  private_host_zone_reverse = "${data.terraform_remote_state.vpc.private_host_zone_reverse}"
  private_domain_name = "${data.terraform_remote_state.vpc.private_domain_name}"

}

output cluster { value = "${module.ecs_cluster.cluster}"}
output cluster_nodes { value = "${module.ecs_cluster.cluster_nodes}"}
output efs_mount_point { value = "${module.ecs_cluster.efs_mount_point}"}
output log_group { value = "${module.ecs_cluster.log_group}"}
output sg_cluster_access { value = "${module.ecs_cluster.sg_cluster_access}"}

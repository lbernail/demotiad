variable "region" {
  type = "string"
}

variable "state_bucket" {
  type = "string"
}

variable "vpc_state_key" {
  type = "string"
}

variable "key_name" {
  type = "string"
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

module ecs_cluster {
  source = "../modules/ecs_cluster"  

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}" 
  sg_ssh = "${data.terraform_remote_state.vpc.sg_ssh}"
  subnets = "${data.terraform_remote_state.vpc.private_subnets}"
  ecs_key = "${var.key_name}" 

  internal_ports = [ "80" ]
  external_sources = [ 
  ]

  private_host_zone = "${data.terraform_remote_state.vpc.private_host_zone}"
  private_host_zone_reverse = "${data.terraform_remote_state.vpc.private_host_zone_reverse}"
  private_domain_name = "${data.terraform_remote_state.vpc.private_domain_name}"

}

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

module consul_cluster {
  source = "../modules/consul_cluster"  

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}" 
  sg_ssh = "${data.terraform_remote_state.vpc.sg_ssh}"
  sg_admin = "${data.terraform_remote_state.vpc.sg_admin}"
  subnets = "${data.terraform_remote_state.vpc.private_subnets}"
  consul_key = "${var.key_name}" 

  private_host_zone = "${data.terraform_remote_state.vpc.private_host_zone}"
  private_host_zone_reverse = "${data.terraform_remote_state.vpc.private_host_zone_reverse}"
  private_domain_name = "${data.terraform_remote_state.vpc.private_domain_name}"

}

output consul_servers {
  value = ["${module.consul_cluster.consul_servers}"]
}
output consul_servers_ips {
  value = ["${module.consul_cluster.consul_server_ips}"]
}
output sg_consul_client{
  value = "${module.consul_cluster.sg_consul_client}"
}
output sg_consul_server{
  value = "${module.consul_cluster.sg_consul_server}"
}

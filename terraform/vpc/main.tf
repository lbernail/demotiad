variable "region" {
  type = "string"
}

variable "cidr_block" {
  type = "string"
}

variable "vpc_name" {
  type = "string"
}

variable "domain" {
  type = "string"
}

provider "aws" {
  region = "${var.region}"
}

module "base_network" {
  source         = "../modules/base_network"
  region         = "${var.region}"
  cidr_block     = "${var.cidr_block}"
  vpc_name       = "${var.vpc_name}"
  vpc_short_name = "${var.domain}"
}

module "private_dns" {
  source              = "../modules/dns_zone"
  private_domain_name = "${var.domain}"
  vpc_cidr            = "${module.base_network.vpc_cidr}"
  vpc                 = "${module.base_network.vpc_id}"
}

output "vpc_id" {
  value = "${module.base_network.vpc_id}"
}

output "vpc_cidr" {
  value = "${module.base_network.vpc_cidr}"
}

output "region" {
  value = "${var.region}"
}

output "azs" {
  value = "${module.base_network.azs}"
}

output "public_subnets" {
  value = ["${module.base_network.public_subnets}"]
}

output "public_subnets_cidr_block" {
  value = ["${module.base_network.public_subnets_cidr_block}"]
}

output "private_subnets" {
  value = ["${module.base_network.private_subnets}"]
}

output "private_subnets_cidr_block" {
  value = ["${module.base_network.private_subnets_cidr_block}"]
}

output "vpc_short_name" {
  value = "${module.base_network.vpc_short_name}"
}

output "vpc_name" {
  value = "${var.vpc_name}"
}

output "sg_remote_access" {
  value = "${module.base_network.sg_remote_access}"
}
output "sg_admin" {
  value = "${module.base_network.sg_admin}"
}
output "sg_ssh" {
  value = "${module.base_network.sg_ssh}"
}
output "private_domain_name" {
  value = "${module.private_dns.private_domain_name}"
}

output "private_host_zone" {
  value = "${module.private_dns.private_host_zone}"
}

output "private_host_zone_reverse" {
  value = "${module.private_dns.private_host_zone_reverse}"
}

output "dns_servers" {
  value = "${module.private_dns.dns_servers}"
}

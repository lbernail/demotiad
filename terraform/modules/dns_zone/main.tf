variable "private_domain_name" {}
variable "vpc_cidr" {}
variable "vpc" {}

resource "aws_route53_zone" "private" {
  name   = "${var.private_domain_name}"
  vpc_id = "${var.vpc}"
}

resource "aws_route53_zone" "private_reverse" {
  name   = "${replace(var.vpc_cidr,"/([0-9]+).([0-9]+)..*/","$2.$1")}.in-addr.arpa."
  vpc_id = "${var.vpc}"
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["${cidrhost(var.vpc_cidr, "2") }"]
  domain_name = "${var.private_domain_name}"

  tags {
    Name = "${var.private_domain_name} PRIVATE DNS"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${var.vpc}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_resolver.id}"
}

output "private_domain_name" {
  value = "${var.private_domain_name}"
}

output "private_host_zone" {
  value = "${aws_route53_zone.private.zone_id}"
}

output "private_host_zone_reverse" {
  value = "${aws_route53_zone.private_reverse.zone_id}"
}

output "dns_servers" {
  value = "${list(cidrhost(var.vpc_cidr, "2")) }"
}

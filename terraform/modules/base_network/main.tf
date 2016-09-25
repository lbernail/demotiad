variable "region" {}

variable "cidr_block" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "subnet_bits" {
  type    = "string"
  default = "8"
}

variable "subnet_prv_offset" {
  type    = "string"
  default = "128"
}

variable "vpc_name" {
  type    = "string"
  default = "Terraform VPC"
}

variable "vpc_short_name" {
  type    = "string"
  default = "terarform-vpc"
}

provider "aws" {
  region = "${var.region}"
}

variable "azs" {
  type = "map"

  default = {
    "eu-west-1" = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags {
    Name = "${var.vpc_name}"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  count      = "${length(var.azs[var.region])}"
  cidr_block = "${cidrsubnet(var.cidr_block, var.subnet_bits, count.index) }"

  availability_zone       = "${element(var.azs[var.region],count.index)}"
  map_public_ip_on_launch = "true"

  tags {
    Name = "${var.vpc_name}_PUB_${count.index}"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  count      = "${length(var.azs[var.region])}"
  cidr_block = "${cidrsubnet(var.cidr_block, var.subnet_bits, var.subnet_prv_offset +count.index) }"

  availability_zone       = "${element(var.azs[var.region],count.index)}"
  map_public_ip_on_launch = "false"

  tags {
    Name = "${var.vpc_name}_PRV_${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name}_IGW"
  }
}

resource "aws_eip" "ng" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.ng.id}"
  subnet_id     = "${aws_subnet.public.0.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name}_PUB_RIB"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "rtap" {
  count          = "${length(var.azs[var.region])}"
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name}_PRV_RIB"
  }
}

resource "aws_route" "private_default" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.gw.id}"
}

resource "aws_route_table_association" "rtaprv" {
  count          = "${length(var.azs[var.region])}"
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "region" {
  value = "${var.region}"
}

output "azs" {
  value = "${var.azs[var.region]}"
}

output "public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}

output "public_subnets_cidr_block" {
  value = ["${aws_subnet.public.*.cidr_block}"]
}

output "private_subnets" {
  value = ["${aws_subnet.private.*.id}"]
}

output "private_subnets_cidr_block" {
  value = ["${aws_subnet.private.*.cidr_block}"]
}

output "vpc_short_name" {
  value = "${var.vpc_short_name}"
}

output "vpc_name" {
  value = "${var.vpc_name}"
}

output "vpc_cidr" {
  value = "${var.cidr_block}"
}

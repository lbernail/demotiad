variable "vpc_id" {
  type = "string"
}

variable "subnets" {
  type = "list"
}

variable "private_host_zone" {
  type = "string"
}

variable "private_host_zone_reverse" {
  type = "string"
}

variable "private_domain_name" {
  type = "string"
}

variable "sg_ssh" {
  type = "string"
}

variable "sg_admin" {
  type = "string"
}

variable "cluster_id" {
  type = "string"
  default ="consul"
}

variable "cluster_name" {
  type = "string"
  default ="Consul"
}

variable "consul_servers" {
  type = "list"
  default = ["consul0","consul1","consul2"]
}

variable "consul_version" {
  type = "string"
  default = "0.7.0"
}
variable "consul_ami_basename" {
  type = "string"
  default = "consul-debian-*"
}

variable "consul_server_type" {
  type = "string"
  default = "t2.micro"
}

variable "consul_key" {}

variable "consul_servers_tcp" {
  type = "list"
  default = [ "8300", "8301", "8302" ]
}

variable "consul_servers_udp" {
  type = "list"
  default = [ "8301", "8302" ]
}

variable "consul_clients_tcp" {
  type = "list"
  default = ["8500","8600"]
}

variable "consul_clients_udp" {
  type = "list"
  default = ["8600"]
}

variable "ttl" {
  type = "string"
  default = "300"
}

data "aws_ami" "consul" {
  most_recent = true
  filter {
    name = "name"
    values = "${list(var.consul_ami_basename)}"
  }
  filter {
    name = "tag:ConsulVersion"
    values = "${list(var.consul_version)}"
  }
}


resource "aws_security_group" "consul_client" {
  name        = "${var.cluster_id}-client"
  description = "Client accessing consul"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.cluster_name} Client"
  }
}

resource "aws_security_group" "consul" {
  name        = "${var.cluster_id}-servers"
  description = "Consul internal traffic"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.cluster_name} Servers"
  }
}

resource "aws_security_group_rule" "consul_servers_tcp" {
  count             = "${length(var.consul_servers_tcp)}"
  type              = "ingress"
  from_port         = "${var.consul_servers_tcp[count.index]}"
  to_port           = "${var.consul_servers_tcp[count.index]}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_servers_udp" {
  count             = "${length(var.consul_servers_udp)}"
  type              = "ingress"
  from_port         = "${var.consul_servers_udp[count.index]}"
  to_port           = "${var.consul_servers_udp[count.index]}"
  protocol          = "udp"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_clients_tcp" {
  count                    = "${length(var.consul_clients_tcp)}"
  type                     = "ingress"
  from_port                = "${var.consul_clients_tcp[count.index]}"
  to_port                  = "${var.consul_clients_tcp[count.index]}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.consul.id}"
  source_security_group_id = "${aws_security_group.consul_client.id}"
}

resource "aws_security_group_rule" "consul_clients_udp" {
  count                    = "${length(var.consul_clients_udp)}"
  type                     = "ingress"
  from_port                = "${var.consul_clients_udp[count.index]}"
  to_port                  = "${var.consul_clients_udp[count.index]}"
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.consul.id}"
  source_security_group_id = "${aws_security_group.consul_client.id}"
}

resource "aws_security_group_rule" "consul_admin_tcp" {
  count                    = "${length(var.consul_clients_tcp)}"
  type                     = "ingress"
  from_port                = "${var.consul_clients_tcp[count.index]}"
  to_port                  = "${var.consul_clients_tcp[count.index]}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.consul.id}"
  source_security_group_id = "${var.sg_admin}"
}

resource "aws_security_group_rule" "consul_admin_udp" {
  count                    = "${length(var.consul_clients_udp)}"
  type                     = "ingress"
  from_port                = "${var.consul_clients_udp[count.index]}"
  to_port                  = "${var.consul_clients_udp[count.index]}"
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.consul.id}"
  source_security_group_id = "${var.sg_admin}"
}

module "consul_servers" {
  source = "../instances"
  ami_id= "${data.aws_ami.consul.id}"
  name = "${var.consul_servers}"
  type = "${var.consul_server_type}"
  key  = "${var.consul_key}"
  subnet = "${var.subnets}"
  security_groups = "${list(var.sg_ssh,aws_security_group.consul.id)}"
  user_data = "${data.template_file.consul_config.rendered}"

  private_zone_id = "${var.private_host_zone}"
  reverse_zone_id = "${var.private_host_zone_reverse}"
  domain_name     = "${var.private_domain_name}"
}

data "template_file" "consul_config" {
  template = "${file("${path.module}/files/config_consul.tpl.sh")}"

  vars {
    TF_CONSUL_SERVERS = "${join(",",var.consul_servers)}"
    TF_CONSUL_ROLE    = "server"
    TF_CONSUL_OPTIONS = ""
    TF_CONSUL_PUBLIC = "yes"
  }
}

output "consul_server_ips" {
  value = ["${module.consul_servers.private_ip}"]
}

output "consul_servers" {
  value = ["${module.consul_servers.private_dns}"]
}

output "sg_consul_client" {
  value = "${aws_security_group.consul_client.id}"
}

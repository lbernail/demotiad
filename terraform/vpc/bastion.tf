variable bastion_ami {
    type = "map"
    default {
       distrib = "debian"
       version = "debian-8"
    }
}

variable bastion_instance_type {
    type = "string"
    default = "t2.micro"
}

variable key_name {
    type = "string"
}

variable "public_zone" {
  type = "string"
}

variable "bastion_name" {
  type = "string"
  default = "bastion"
}

variable "bastion_ttl" {
  type = "string"
  default = "300"
}

module "ami" {
  source         = "../modules/ami"
}

data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "name"
    values = "${list(module.ami.basenames[var.bastion_ami["version"]])}"
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = "${list(module.ami.owners[var.bastion_ami["distrib"]])}"

}

module "bastion" {
  source = "../modules/instances"
  name   = ["bastion"]

  ami_id          = "${data.aws_ami.bastion.id}"
  type            = "${var.bastion_instance_type}"
  key             = "${var.key_name}"
  subnet          = "${module.base_network.public_subnets}"
  security_groups = ["${module.base_network.sg_remote_access}", "${module.base_network.sg_admin}"]

  private_zone_id = "${module.private_dns.private_host_zone}"
  reverse_zone_id = "${module.private_dns.private_host_zone_reverse}"
  domain_name     = "${module.private_dns.private_domain_name}"
}

resource "aws_eip" "bastion" {
  instance = "${module.bastion.id[0]}"
  vpc      = true
}

resource "aws_route53_record" "bastion" {
    zone_id = "${var.public_zone}"
    name = "${var.bastion_name}"
    ttl = "${var.bastion_ttl}"
    type = "A"
    records = ["${aws_eip.bastion.public_ip}"]
}

output "bastion" {
   value = "${aws_route53_record.bastion.fqdn}"
}

output "bastion_ip" {
   value = "${aws_eip.bastion.public_ip}"
}

output "public_zone" {
   value = "${var.public_zone}"
}


variable bastion_distrib {
    type = "string"
    default = "debian-8.4"
}

variable bastion_instance_type {
    type = "string"
    default = "t2.micro"
}

variable key_name {
    type = "string"
}

module "ami" {
  source         = "../modules/ami"
}

data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "name"
    values = "${list(module.ami.basenames["${var.bastion_distrib}"])}"
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

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

output "bastion" {
   value = "${aws_eip.bastion.public_ip}"
}

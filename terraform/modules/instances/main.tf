variable ami_id {
  type = "string"
}

variable type {
  type = "string"
}

variable key {
  type    = "string"
  default = ""
}

variable subnet {
  type = "list"
}

variable security_groups {
  type = "list"
}

variable name {
  type = "list"
}

variable user_data {
  type    = "string"
  default = ""
}

variable instance_profile {
  type = "string"
  default = ""
}

variable private_zone_id {
  type    = "string"
  default = ""
}

variable record_ttl {
  type    = "string"
  default = "300"
}

variable reverse_zone_id {
  type    = "string"
  default = ""
}

variable domain_name {
  type    = "string"
  default = ""
}

data "template_file" "user_data" {
  count = "${length(var.name)}"
  template = "${file("${path.module}/files/hostname.tpl.sh")}"

  vars {
    hostname = "${var.name[count.index]}"
  }
}

resource "aws_instance" "instance" {
  count = "${length(var.name)}"
  ami                    = "${var.ami_id}"
  instance_type          = "${var.type}"
  key_name               = "${var.key}"
  subnet_id              = "${var.subnet[count.index]}"
  vpc_security_group_ids = ["${var.security_groups}"]
  user_data              = "${data.template_file.user_data.*.rendered[count.index]}\n${var.user_data}"

  iam_instance_profile   = "${var.instance_profile}"

  tags {
    Name = "${var.name[count.index]}"
  }
}

resource "aws_route53_record" "dns_record" {
  count = "${length(var.name)}"
  zone_id = "${var.private_zone_id}"
  name    = "${var.name[count.index]}"
  type    = "A"
  ttl     = "${var.record_ttl}"
  records = ["${aws_instance.instance.*.private_ip[count.index]}"]
}

resource "aws_route53_record" "dns_reverse" {
  count = "${length(var.name)}"
  zone_id = "${var.reverse_zone_id}"
  name    = "${replace(aws_instance.instance.*.private_ip[count.index],"/([0-9]+).([0-9]+).([0-9]+).([0-9]+)/","$4.$3")}"
  type    = "PTR"
  ttl     = "${var.record_ttl}"
  records = ["${var.name[count.index]}.${var.domain_name}"]
}

output "public_ip" {
  value = ["${aws_instance.instance.*.public_ip}"]
}
output "private_ip" {
  value = ["${aws_instance.instance.*.private_ip}"]
}

output "private_dns" {
  value = ["${var.name}"]
}

output "id" {
  value = ["${aws_instance.instance.*.id}"]
}

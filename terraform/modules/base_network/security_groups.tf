variable trusted_networks {
  type    = "list"
  default = ["0.0.0.0/0"]
}

resource "aws_security_group" "remote_access" {
  name        = "${var.vpc_short_name}-remote"
  description = "Allow remote ssh from trusted networks"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.trusted_networks}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.vpc_name} REMOTE ACCESS"
  }
}

resource "aws_security_group" "admin" {
  name        = "${var.vpc_short_name}-admin"
  description = "Admin servers"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.vpc_name} Admin"
  }
}

resource "aws_security_group" "ssh" {
  name        = "${var.vpc_short_name}-ssh"
  description = "Allow all ssh from admin servers"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.admin.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.vpc_name} SSH ACCESS"
  }
}

output "sg_remote_access" {
  value = "${aws_security_group.remote_access.id}"
}

output "sg_admin" {
  value = "${aws_security_group.admin.id}"
}

output "sg_ssh" {
  value = "${aws_security_group.ssh.id}"
}

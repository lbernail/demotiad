variable "vpc_id" {
  type = "string"
}

variable "subnets" {
  type = "list"
}

variable "ecs_servers" {
  type = "list"
  default = [ "ecs0", "ecs1", "ecs2"]
}

variable "all_nodes_tasks" {
  type = "list"
  default = []
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

variable "sg_list" {
  type = "list"
}

variable "cluster_name" {
  type    = "string"
  default = "ecs"
}

variable "cluster_id" {
  type    = "string"
  default = "ecs"
}

variable "ecs_ami_basename" {
  type    = "string"
  default = "amzn-ami-*.i-amazon-ecs-optimized"
}

variable "ecs_server_type" {
  type    = "string"
  default = "t2.micro"
}

variable "ecs_key" {}

variable "ttl" {
  type    = "string"
  default = "300"
}

variable "internal_ports" {
  type    = "list"
}

variable "external_sources" {
  type = "list"
}

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = "${list(var.ecs_ami_basename)}"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}"
}

resource "aws_security_group" "ecs" {
  name        = "${var.cluster_id}-servers"
  description = "Traffic to ECS instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.cluster_name} Servers"
  }
}

resource "aws_security_group_rule" "internal_ports" {
  count             = "${length(var.internal_ports)}"
  type              = "ingress"
  from_port         = "${var.internal_ports[count.index]}"
  to_port           = "${var.internal_ports[count.index]}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ecs.id}"
  self              = true
}

resource "aws_security_group_rule" "external_sources" {
  count                    = "${length(var.external_sources)}"
  type                     = "ingress"
  from_port                = "${lookup(var.external_sources[count.index],"port")}"
  to_port                  = "${lookup(var.external_sources[count.index],"port")}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ecs.id}"
  cidr_blocks = ["${lookup(var.external_sources[count.index],"src")}"]

}

resource "aws_iam_role" "ecs" {
    name = "${var.cluster_id}_ecs_role"
    path = "/"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs" {
    name = "${var.cluster_id}_ecs_role_policy"
    role = "${aws_iam_role.ecs.id}"
    policy = <<EOF
{
    "Statement": [
        {
            "Action": [ 
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:Submit*",
                "ecs:StartTask",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": [ "*" ]
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_instance_profile" "ecs" {
    name = "${var.cluster_id}_ecs_profile"
    roles = ["${aws_iam_role.ecs.name}"]
}

module "ecs_servers" {
  source          = "../instances"
  ami_id          = "${data.aws_ami.ecs.id}"
  name            = "${var.ecs_servers}"
  type            = "${var.ecs_server_type}"
  key             = "${var.ecs_key}"
  subnet          = "${var.subnets}"
  security_groups = "${concat(var.sg_list,list(aws_security_group.ecs.id))}"
  user_data       = "${data.template_file.ecs_config.rendered}"

  instance_profile = "${aws_iam_instance_profile.ecs.id}"

  private_zone_id = "${var.private_host_zone}"
  reverse_zone_id = "${var.private_host_zone_reverse}"
  domain_name     = "${var.private_domain_name}"
}

data "template_file" "ecs_config" {
  template = "${file("${path.module}/files/config_ecs.tpl.sh")}"

  vars {
    TF_ECS_CLUSTER = "${var.cluster_name}"
    TF_ALL_NODES_TASKS = "${join(" ",var.all_nodes_tasks)}"
  }
}

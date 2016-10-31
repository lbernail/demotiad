variable "docker_volume_name" { default = "docker" }

variable "consultmpl_repo" {
  type = "string"
  default = "demotiad/consultmpl"
}

variable "consultmpl_tag" {
  type = "string"
  default = "latest"
}

variable "haproxy_count" {
  type = "string"
  default = "2"
}

variable "dns_alias" {
  type = "string"
  default = "tiad"
}

data "template_file" "haproxy" {
  template = "${file("${path.module}/files/haproxy.tpl.json")}"

  vars {
      TF_ACCOUNT="${data.aws_caller_identity.current.account_id}",
      TF_REGION="${var.region}"
      TF_REPO="${var.consultmpl_repo}"
      TF_TAG="${var.consultmpl_tag}"
      TF_BRIDGE_IP="${var.bridge_ip}"
      TF_VOLUME_NAME = "${var.docker_volume_name}"
  }
}

resource "aws_ecs_task_definition" "haproxy" {
  family = "haproxy"
  container_definitions = "${data.template_file.haproxy.rendered}"

  volume {
    name = "${var.docker_volume_name}"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_ecs_service" "haproxy" {
  name = "consultmpl"
  cluster = "${data.terraform_remote_state.ecs.cluster}"
  task_definition = "${aws_ecs_task_definition.haproxy.arn}"
  desired_count = "${var.haproxy_count}"

  iam_role = "${aws_iam_role.ecs_service.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.haproxy.id}"
    container_name   = "proxy"
    container_port   = "80"
  }
}

resource "aws_iam_role" "ecs_service" {
  name = "ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "ecs_policy"
  role = "${aws_iam_role.ecs_service.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  name   = "front-alb"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [ "0.0.0.0/0", ]
  }
}

resource "aws_alb" "front" {
  name            = "front-alb-ecs"
  subnets         = ["${data.terraform_remote_state.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.lb_sg.id}", "${data.terraform_remote_state.ecs.sg_cluster_access}"]
}


resource "aws_alb_target_group" "haproxy" {
  name     = "haproxy"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
}


resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.front.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.haproxy.id}"
    type             = "forward"
  }
}

resource "aws_route53_record" "web" {
    zone_id = "${data.terraform_remote_state.vpc.public_zone}"
    name = "${var.dns_alias}"
    type = "A"
    alias {
        name = "${aws_alb.front.dns_name}"
        zone_id = "${aws_alb.front.zone_id}"
        evaluate_target_health = "false"
    }
}

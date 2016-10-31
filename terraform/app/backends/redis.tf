variable "bridge_ip" {
  type = "string"
  default = "172.17.0.1"
}

variable "redis_volume_name" {
  type = "string"
  default = "redis"
}

data "template_file" "redis" {
  template = "${file("${path.module}/files/redis.tpl.json")}"

  vars {
      TF_REGION = "${var.region}"
      TF_LOG_GROUP = "${data.terraform_remote_state.ecs.log_group}"
      TF_REDIS_VOLUME = "${var.redis_volume_name}"
  }
}

resource "aws_ecs_task_definition" "redis" {
  family = "redis"
  container_definitions = "${data.template_file.redis.rendered}"

  volume {
    name = "${var.redis_volume_name}"
    host_path = "${data.terraform_remote_state.ecs.efs_mount_point}/redis"
  }

}

resource "aws_ecs_service" "redis" {
  name = "redis"
  cluster = "${data.terraform_remote_state.ecs.cluster}"
  task_definition = "${aws_ecs_task_definition.redis.arn}"
  desired_count = 1
}


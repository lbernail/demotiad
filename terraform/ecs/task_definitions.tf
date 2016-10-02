variable "bridge_ip" { default = "172.17.0.1" }
variable "docker_volume_name" { default = "docker" }

data "template_file" "consul_agent" {
  template = "${file("${path.module}/files/consul_agent.tpl.json")}"

  vars {
    TF_CONSUL_JOIN = "${data.terraform_remote_state.consul.consul_servers[0]}"
    TF_DNS_SERVER = "${data.terraform_remote_state.vpc.dns_servers[0]}"
  }
}

resource "aws_ecs_task_definition" "consul" {
  family = "consul"
  network_mode = "host"
  container_definitions = "${data.template_file.consul_agent.rendered}"
}

data "template_file" "registrator" {
  template = "${file("${path.module}/files/registrator.tpl.json")}"

  vars {
    TF_BRIDGE_IP = "${var.bridge_ip}"
    TF_VOLUME_NAME = "${var.docker_volume_name}"
  }
}

resource "aws_ecs_task_definition" "registrator" {
  family = "registrator"
  network_mode = "host"
  container_definitions = "${data.template_file.registrator.rendered}"
  
  volume {
    name = "${var.docker_volume_name}"
    host_path = "/var/run/docker.sock"
  }

}

data "template_file" "cadvisor" {
  template = "${file("${path.module}/files/cadvisor.tpl.json")}"

  vars {
  }
}

resource "aws_ecs_task_definition" "cadvisor" {
  family = "cadvisor"
  container_definitions = "${data.template_file.cadvisor.rendered}"
  
  volume {
    name = "root"
    host_path = "/"
  }

  volume {
    name = "var_run"
    host_path = "/var/run"
  }

  volume {
    name = "sys"
    host_path = "/sys"
  }

  volume {
    name = "cgroup"
    host_path = "/cgroup"
  }

  volume {
    name = "var_lib_docker"
    host_path = "/var/lib/docker"
  }
}

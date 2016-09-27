variable "bridge_ip" { default = "172.17.0.1" }

data "template_file" "consul_agent" {
  template = "${file("${path.module}/files/consul_agent.tpl.json")}"

  vars {
    TF_CONSUL_JOIN = "${data.terraform_remote_state.consul.consul_servers[0]}"
    TF_DNS_SERVER = "${data.terraform_remote_state.vpc.dns_servers[0]}"
    TF_BRIDGE_IP = "${var.bridge_ip}"
  }
}

resource "aws_ecs_task_definition" "consul" {
  family = "consul"
  network_mode = "host"
  container_definitions = "${data.template_file.consul_agent.rendered}"
}

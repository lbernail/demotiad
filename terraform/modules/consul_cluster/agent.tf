variable "consul_agent_type" {
  type = "string"
  default = "t2.nano"
}

module "consul_agent" {
  source = "../instances"
  ami_id= "${data.aws_ami.consul.id}"
  name = [ "consulagent" ]
  type = "${var.consul_agent_type}"
  key  = "${var.consul_key}"
  subnet = "${var.subnets}"
  security_groups = "${list(var.sg_ssh,aws_security_group.consul.id)}"
  user_data = "${data.template_file.agent_consul_config.rendered}"

  private_zone_id = "${var.private_host_zone}"
  reverse_zone_id = "${var.private_host_zone_reverse}"
  domain_name     = "${var.private_domain_name}"
}

data "template_file" "agent_consul_config" {
  template = "${file("${path.module}/files/config_consul.tpl.sh")}"

  vars {
    TF_CONSUL_SERVERS = "${join(",",var.consul_servers)}"
    TF_CONSUL_ROLE    = "client"
    TF_CONSUL_OPTIONS = "-ui"
    TF_CONSUL_PUBLIC = "yes"
  }
}

output "consul_agent" {
    value = "http://consulagent:8500"
}

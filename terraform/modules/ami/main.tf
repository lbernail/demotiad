variable "basenames" {
  type = "map"

  default = {
    "debian-8.4"   = "debian-jessie-amd64-hvm*"
    "ubuntu-16.04" = "ubuntu/images-milestone/hvm-ssd/ubuntu-xenial-16.04*"
  }
}

output "basenames" { value = "${var.basenames}"}

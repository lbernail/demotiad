variable "basenames" {
  type = "map"

  default = {
    "debian-8"   = "debian-jessie-amd64-hvm*"
    "ubuntu-16.04" = "ubuntu/images-milestone/hvm-ssd/ubuntu-xenial-16.04*"
  }
}

variable "owners" {
  type = "map"

  default = {
    "debian"   = "379101102735"
    "ubuntu" = "099720109477"
  }
}

output "basenames" { value = "${var.basenames}"}
output "owners" { value = "${var.owners}"}

terraform {
  backend "s3" {
    bucket = "tfstates"
    key    = "demotiad/frontblue"
    region = "eu-west-1"
  }
}

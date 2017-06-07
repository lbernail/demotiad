terraform {
  backend "s3" {
    bucket = "tfstates"
    key    = "demotiad/frontgreen"
    region = "eu-west-1"
  }
}

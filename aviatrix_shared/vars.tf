variable "cidr_prefix" {}
variable "name_suffix" {}
variable "region" {}
variable "gw_size" {}
variable "vpc_name" {}
variable "path_public_key" {}
variable "account_name" {}
variable "transit_gw" {}
variable "vpc_count" {
   default = 0
}
variable "AMI" {
  type = "map"
  default = {
    ca-central-1 = "ami-018b3065"
    us-east-1    = "ami-aa2ea6d0"
    us-east-2    = "ami-82f4dae7"
    us-west-1    = "ami-45ead225"
    us-west-2    = "ami-0def3275"

  }
}


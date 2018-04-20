variable "onprem_count" {}
variable "onprem_cidr_prefix" {}
variable "account_name" {}
variable "name_suffix" {}
variable "onprem_gw_name" {}
variable "onprem_gw_size" {}
variable "region" {}
variable "vgw_id" {}
variable "onprem_path_public_key" {}
variable "remote_subnet" {}
variable "transit_gw" {}
variable "vgw_conn_check" {}

#AWS
#variable "AWS_REGION" {}
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


#variable "INSTANCE_USERNAME" {
#  default = "ubuntu"
#}
#variable "PATH_TO_PRIVATE_KEY" {
#  default = "mykey"
#}
#variable "PATH_TO_PUBLIC_KEY" {
#  default = "mykey.pub"
#}



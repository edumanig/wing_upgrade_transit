variable "account_name" {}
variable "account_password" {}
variable "account_email" {}
variable "aws_account_number" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "vgw_connection_name" {}
variable "bgp_local_as" {}
variable "controller_ip" {}
variable "controller_username" {}
variable "controller_password" {}
variable "controller_custom_version" {}

variable "transit_gateway_name" {}
variable "transit_gateway_size" {}
variable "transit_cidr_prefix" {}
variable "transit_region" {}
variable "transit_count" {}

variable "shared_gateway_name" {}
variable "shared_gateway_size" {}
variable "shared_cidr_prefix" {}
variable "shared_region" {}
variable "shared_count" {}

variable "spoke_gateway_size" {}
variable "spoke_count_us_east_1" {}
variable "spoke_count_us_east_2" {}
variable "spoke_count_us_west_1" {}
variable "spoke_count_us_west_2" {}
variable "spoke_cidr_prefix_us_east_1" {}
variable "spoke_cidr_prefix_us_east_2" {}
variable "spoke_cidr_prefix_us_west_1" {}
variable "spoke_cidr_prefix_us_west_2" {}

variable "onprem_count" {}
variable "onprem_region" {}
variable "onprem_cidr_prefix" {}
variable "onprem_gateway_name" {}
variable "onprem_gateway_size" {}
variable "s2c_remote_subnet" {}



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
variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}
variable "PATH_TO_PRIVATE_KEY" {
  default = "mykey"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "mykey.pub"
}

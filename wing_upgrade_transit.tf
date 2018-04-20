# Sample Aviatrix terraform configuration to create complete transit network solution
# This configuration creates the following:
# 1. create cloud account on Aviatrix controller, 
# 2. launches transit VPC and Gateway
# 3. creates VGW connection with transit VPC
# 4. launches a spoke GW, and attach with transit VPC. this is by calling module

# upgrade controller

resource "aviatrix_upgrade" "upgrade32" {
    version = "${var.controller_custom_version}"
}

resource "aws_vpn_gateway" "vpn_gw" {
  tags {
    Name = "dynamic-vgw"
  }
  depends_on = ["aviatrix_upgrade.upgrade32"]
}

# create Aviatrix cloud account
module "aviatrix_cloud_account" {
  source             = "aviatrix_account"
  account_name       = "${var.account_name}"
  account_password   = "${var.account_password}" 
  account_email      = "${var.account_email}" 
  cloud_type         = "1" 
  aws_account_number = "${var.aws_account_number}"
  aws_access_key     = "${var.aws_access_key}"
  aws_secret_key     = "${var.aws_secret_key}"
}
  #depends_on = ["aviatrix_upgrade.upgrade32"]
  #custom_version = "${module.aviatrix_custom_version.aviatrix_loaded_version}"
 
# Create TRANSIT 
module "transit_vpc" {
  source = "aviatrix_transit"
  providers = {
    aws = "aws.us-east-2"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  vpc_count = "${var.transit_count}"
  region = "${var.transit_region}"
  gw_size = "${var.transit_gateway_size}"
  name_suffix = "${var.transit_gateway_name}"
  cidr_prefix = "${var.transit_cidr_prefix}"
  vgw_id = "${aws_vpn_gateway.vpn_gw.id}"
  vpc_name = "transit"
  bgp_local_as = "${var.bgp_local_as}"
  vgw_connection_name = "${var.vgw_connection_name}"
  shared_gw_check = "${module.shared_services_vpc.shared_gateway_name}"
}

# Create Shared spoke
module "shared_services_vpc" {
  source = "aviatrix_shared"
  providers = {
    aws = "aws.us-east-2"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  vpc_count = "${var.shared_count}"
  region = "${var.shared_region}"
  gw_size = "${var.shared_gateway_size}"
  name_suffix = "${var.shared_gateway_name}"
  cidr_prefix = "${var.shared_cidr_prefix}"
  vpc_name = "shared"
  transit_gw = "${element(module.transit_vpc.transit_gateway_name,0)}"
  path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
}
# Create OnPrem spoke
module "onprem" {
  source = "aviatrix_onprem"
  providers = {
    aws = "aws.us-east-2"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  onprem_count = "${var.onprem_count}"
  onprem_gw_name = "${var.onprem_gateway_name}"
  vgw_id = "${aws_vpn_gateway.vpn_gw.id}"
  region = "${var.onprem_region}"
  onprem_gw_size = "${var.onprem_gateway_size}"
  name_suffix = "${var.onprem_gateway_name}"
  onprem_cidr_prefix = "${var.onprem_cidr_prefix}"
  onprem_path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
  remote_subnet = "${var.s2c_remote_subnet}"
  transit_gw = "${element(module.transit_vpc.transit_gateway_name,0)}"
  vgw_conn_check = "${module.transit_vpc.vgw_connection}"
}

module "spoke_us_east_1" {
  source = "aviatrix_spoke"
  providers = {
    aws = "aws.us-east-1"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  transit_gateway_name = "${element(module.transit_vpc.transit_gateway_name,0)}"
  spoke_count = "${var.spoke_count_us_east_1}"
  spoke_region = "us-east-1"
  spoke_gw_size = "${var.spoke_gateway_size}"
  name_suffix = "wing-us-east-1"
  shared_gw_name = "${var.shared_gateway_name}"
  spoke_cidr_prefix = "${var.spoke_cidr_prefix_us_east_1}"
  path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
}

module "spoke_us_east_2" {
  source = "aviatrix_spoke"
  providers = {
    aws = "aws.us-east-2"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  transit_gateway_name = "${element(module.transit_vpc.transit_gateway_name,0)}"
  spoke_count = "${var.spoke_count_us_east_2}"
  spoke_region = "us-east-2"
  spoke_gw_size = "${var.spoke_gateway_size}"
  name_suffix = "wing-us-east-2"
  shared_gw_name = "${var.shared_gateway_name}"
  spoke_cidr_prefix = "${var.spoke_cidr_prefix_us_east_2}"
  path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
}

module "spoke_us_west_1" {
  source = "aviatrix_spoke"
  providers = {
    aws = "aws.us-west-1"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  transit_gateway_name = "${element(module.transit_vpc.transit_gateway_name,0)}"
  spoke_count = "${var.spoke_count_us_west_1}"
  spoke_region = "us-west-1"
  spoke_gw_size = "${var.spoke_gateway_size}"
  name_suffix = "wing-us-west-1"
  shared_gw_name = "${var.shared_gateway_name}"
  spoke_cidr_prefix = "${var.spoke_cidr_prefix_us_west_1}"
  path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
}

module "spoke_us_west_2" {
  source = "aviatrix_spoke"
  providers = {
    aws = "aws.us-west-2"
  }
  account_name = "${module.aviatrix_cloud_account.aviatrix_account_name}"
  transit_gateway_name = "${element(module.transit_vpc.transit_gateway_name,0)}"
  spoke_count = "${var.spoke_count_us_west_2}"
  spoke_region = "us-west-2"
  name_suffix = "wing-us-west-2"
  spoke_gw_size = "${var.spoke_gateway_size}"
  shared_gw_name = "${var.shared_gateway_name}"
  spoke_cidr_prefix = "${var.spoke_cidr_prefix_us_west_2}"
  path_public_key = "${var.PATH_TO_PUBLIC_KEY}"
}

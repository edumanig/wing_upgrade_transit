vgw_connection_name = "wing_vgw_bgp_s2c_conn"
bgp_local_as = 6510
controller_custom_version = "3.2"

transit_gateway_name = "wing-transit-GW"
transit_gateway_size = "t2.micro"
transit_cidr_prefix = "192.168"
transit_region = "us-east-2"
transit_count = 1

shared_gateway_name = "wing-spoke-shared-GW"
shared_gateway_size = "t2.micro"
shared_region = "us-east-2"
shared_cidr_prefix = "10.224"
shared_count = 1

onprem_count = 1
onprem_gateway_name = "wing-OnPrem-GW"
onprem_gateway_size = "t2.micro"
onprem_region = "us-east-2"
onprem_cidr_prefix = "172.16"
s2c_remote_subnet = "10.224.0.0/24,10.45.0.0/24,10.46.0.0/24,10.47.0.0/24,10.48.0.0/24"

# region parameters
spoke_gateway_size = "t2.micro"

# us-east-2
spoke_count_us_east_2 = 1
spoke_cidr_prefix_us_east_2 = "10.46"

# us-west-2
spoke_count_us_west_2 = 1
spoke_cidr_prefix_us_west_2 = "10.48"

# us-east-1
spoke_count_us_east_1 = 0
spoke_cidr_prefix_us_east_1 = "10.45"
# us-west-1
spoke_count_us_west_1 = 0
spoke_cidr_prefix_us_west_1 = "10.47"

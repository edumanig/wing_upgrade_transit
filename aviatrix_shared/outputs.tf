output "shared_gateway_name" {
    value = "${aviatrix_spoke_vpc.test_spoke.*.gw_name}"
}

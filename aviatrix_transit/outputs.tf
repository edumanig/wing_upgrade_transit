output "vgw_connection" {
    value = ["${aviatrix_vgw_conn.test_vgw_conn.*.conn_name}"]
}

output "transit_gateway_name" {
    value = ["${aviatrix_transit_vpc.test_transit_gw.*.gw_name}"]
}

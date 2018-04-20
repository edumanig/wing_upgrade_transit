#########################
##### AWS resources #####
#########################

## Create AWS VPC TRANSIT side
## -----------------------------------

# Internet VPC
resource "aws_vpc" "VPC" {
    count = "${var.vpc_count}"
    cidr_block = "${var.cidr_prefix}.${count.index}.0/24"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "${var.name_suffix}-VPC-${count.index}-${var.region}"
    }
}
# Subnets
resource "aws_subnet" "public" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.VPC.*.id,count.index)}"
    cidr_block = "${var.cidr_prefix}.${count.index}.0/24"
    map_public_ip_on_launch = "true"
    tags {
        Name = "${var.name_suffix}-VPC-public-${count.index}-${var.region}"
    }
    depends_on = ["aws_vpc.VPC"]
}
# Internet GW
resource "aws_internet_gateway" "VPC-gw" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.VPC.*.id,count.index)}"
    tags {
        Name = "${var.name_suffix}-VPC-gw-${count.index}-${var.region}"
    }
    depends_on = ["aws_vpc.VPC"]
}
# route tables
resource "aws_route_table" "VPC-route" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.VPC.*.id,count.index)}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${element(aws_internet_gateway.VPC-gw.*.id,count.index)}"
    }
    lifecycle {
        ignore_changes = ["route"]
    }
    tags {
        Name = "${var.name_suffix}-VPC-route-${count.index}-${var.region}"
    }
    depends_on = ["aws_vpc.VPC","aws_internet_gateway.VPC-gw"]
}

# route associations public
resource "aws_route_table_association" "VPC-ra" {
    count = "${var.vpc_count}"
    subnet_id = "${element(aws_subnet.public.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.VPC-route.*.id,count.index)}"
    depends_on = ["aws_subnet.public","aws_route_table.VPC-route","aws_internet_gateway.VPC-gw","aws_vpc.VPC"]
}
## END -------------------------------

resource "aviatrix_transit_vpc" "test_transit_gw" {
    count = "${var.vpc_count}"
    cloud_type = 1
    account_name = "${var.account_name}"
    gw_name= "${var.name_suffix}"
    vpc_id = "${element(aws_vpc.VPC.*.id,count.index)}"
    vpc_reg = "${var.region}"
    vpc_size = "${var.gw_size}"
    subnet = "${aws_subnet.public.cidr_block}"
    ha_subnet = "${aws_subnet.public.cidr_block}"
    depends_on = ["aws_route_table_association.VPC-ra","aws_subnet.public","aws_vpc.VPC","aws_internet_gateway.VPC-gw","aws_subnet.public","aws_vpc.VPC"]
}

# Create VGW connection with transit VPC.
resource "aviatrix_vgw_conn" "test_vgw_conn" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.VPC.*.id,count.index)}"
    conn_name = "${var.vgw_connection_name}"
    gw_name = "${var.name_suffix}"
    bgp_vgw_id = "${var.vgw_id}"
    bgp_local_as_num = "${var.bgp_local_as}"
    depends_on = ["aviatrix_transit_vpc.test_transit_gw","aws_route_table_association.VPC-ra"]
}

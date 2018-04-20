data "aws_availability_zones" "available" {}

#Create OnPrem VPC
## -----------------------------------
# Internet VPC
resource "aws_vpc" "OnPrem-VPC" {
    count = "${var.onprem_count}"
    cidr_block = "${var.onprem_cidr_prefix}.${count.index}.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "OnPrem-VPC-${var.region}"
    }
}
# Subnets
resource "aws_subnet" "OnPrem-VPC-public" {
    count = "${var.onprem_count}"
    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
    cidr_block = "${var.onprem_cidr_prefix}.0.0/24"
    map_public_ip_on_launch = "true"
    tags {
        Name = "OnPrem-VPC-public-${var.region}"
    }
}
# Internet GW
resource "aws_internet_gateway" "OnPrem-VPC-gw" {
    count = "${var.onprem_count}"
    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
    tags {
        Name = "OnPrem-VPC-gw-${var.region}"
    }
}
# route tables
resource "aws_route_table" "OnPrem-VPC-route" {
    count = "${var.onprem_count}"
    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.OnPrem-VPC-gw.id}"
    }
    tags {
        Name = "OnPrem-VPC-route-${var.region}"
    }
}
# route associations public
resource "aws_route_table_association" "OnPrem-VPC-ra" {
    count = "${var.onprem_count}"
    subnet_id = "${element(aws_subnet.OnPrem-VPC-public.*.id,count.index)}"
    route_table_id = "${aws_route_table.OnPrem-VPC-route.id}"
    depends_on = ["aws_subnet.OnPrem-VPC-public","aws_route_table.OnPrem-VPC-route","aws_internet_gateway.OnPrem-VPC-gw","aws_vpc.OnPrem-VPC"]
}
## END -------------------------------

## Create AWS Key Pair 
### -----------------------------------
#resource "aws_key_pair" "onprem_keypair" {
#  key_name = "onprem_keypair"
#  public_key = "${file("${var.onprem_path_public_key}")}"
#}
#
### END -------------------------------
#
## Create Security Group
### -----------------------------------
### Security Group Shared Services Side
### -----------------------------------
#resource "aws_security_group" "allow-ssh-ping" {
#    count = "${var.onprem_count}"
#    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
#    name = "allow-ssh-OnPrem-${count.index}"
#    description = "security group that allows ssh and all egress traffic"
#    egress {
#        from_port = 0
#        to_port = 0
#        protocol = "-1"
#        cidr_blocks = ["0.0.0.0/0"]
#    }
#    ingress {
#      from_port   = 22
#      to_port     = 22
#      protocol    = "tcp"
#      cidr_blocks = ["0.0.0.0/0"]
#    }
#    ingress {
#      from_port = 0
#      to_port = 0
#      protocol = "-1"
#      cidr_blocks = ["0.0.0.0/0"]
#    }
#    tags {
#      Name = "allow-ssh-ping"
#    }
#}
## END -------------------------------

## Create OnPrem Linux VM
### -----------------------------------
#resource "aws_instance" "Linux-On-Prem" {
#    count = "${var.onprem_count}"
#    ami           = "${lookup(var.AMI, var.region)}"
#    instance_type = "${var.onprem_gw_size}"
#    # the VPC subnet
#    subnet_id = "${element(aws_subnet.OnPrem-VPC-public.*.id,count.index)}"
#    # the security group
#    vpc_security_group_ids = ["${aws_security_group.allow-ssh-ping.id}"]
#    # the public SSH key
#    key_name = "${aws_key_pair.onprem_keypair.key_name}"
#    tags {
#        Name = "Linux-On-Prem"
#    } 
#    depends_on = ["aws_subnet.OnPrem-VPC-public","aws_route_table.OnPrem-VPC-route","aws_internet_gateway.OnPrem-VPC-gw","aws_vpc.OnPrem-VPC"]
#}
##    #ami           = "ami-0def3275"
### END -------------------------------


## Create Aviatrix OnPrem gateway
## -----------------------------------
resource "aviatrix_gateway" "OnPrem-GW" {
    cloud_type = 1
    account_name = "${var.account_name}"
    gw_name = "${var.onprem_gw_name}"
    count = "${var.onprem_count}"
    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
    vpc_reg = "${var.region}"
    vpc_size = "${var.onprem_gw_size}"
    vpc_net = "${element(aws_subnet.OnPrem-VPC-public.*.cidr_block,count.index)}"
    depends_on = ["aws_subnet.OnPrem-VPC-public","aws_route_table.OnPrem-VPC-route","aws_internet_gateway.OnPrem-VPC-gw","aws_vpc.OnPrem-VPC"]
}
## END -------------------------------

## Create AWS customer gateway & VGW towards aviatrix OnPrem Gateway
## -----------------------------------------------------------------
resource "aws_customer_gateway" "customer_gateway" {
    bgp_asn    = 6588
    count = "${var.onprem_count}"
    #edsel
    ip_address = "${element(aviatrix_gateway.OnPrem-GW.*.public_ip,count.index)}"
    type       = "ipsec.1"
    tags {
       Name = "onprem-gateway"
    }
}
resource "aws_vpn_connection" "onprem" {
    vpn_gateway_id      = "${var.vgw_id}"
    customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
    type                = "ipsec.1"
    static_routes_only  = true
    tags {
       Name = "site2cloud-to-vgw"
    }
    depends_on = ["aviatrix_gateway.OnPrem-GW"]
}
    #vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
# original onprem CIDR block
resource "aws_vpn_connection_route" "onprem1" {
    count = "${var.onprem_count}"
    destination_cidr_block = "${element(aws_subnet.OnPrem-VPC-public.*.cidr_block,count.index)}"
    vpn_connection_id = "${aws_vpn_connection.onprem.id}"
    depends_on = ["aviatrix_gateway.OnPrem-GW","aws_vpc.OnPrem-VPC"]
}
# 2nd static route from onprem
resource "aws_vpn_connection_route" "onprem2" {
    count = "${var.onprem_count}"
    destination_cidr_block = "100.100.100.0/24"
    vpn_connection_id = "${aws_vpn_connection.onprem.id}"
    depends_on = ["aviatrix_gateway.OnPrem-GW","aws_vpc.OnPrem-VPC"]
}
## END -------------------------------

# Aviatrix site2cloud connection facing AWS VGW
## END -------------------------------
resource "aviatrix_site2cloud" "onprem-vgw" {
    count = "${var.onprem_count}"
    vpc_id = "${element(aws_vpc.OnPrem-VPC.*.id,count.index)}"
    gw_name = "${aviatrix_gateway.OnPrem-GW.gw_name}"
    conn_name = "s2c_to_vgw",
    remote_gw_type = "aws",
    remote_gw_ip = "${aws_vpn_connection.onprem.tunnel1_address}",
    remote_subnet = "${var.remote_subnet}",
    pre_shared_key = "${aws_vpn_connection.onprem.tunnel1_preshared_key}"
    depends_on = ["aviatrix_gateway.OnPrem-GW","aws_vpc.OnPrem-VPC"]
}
## END -------------------------------


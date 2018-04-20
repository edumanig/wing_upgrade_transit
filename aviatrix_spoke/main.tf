# AWS Spoke VPCs
data "aws_availability_zones" "available" {}

resource "aws_vpc" "spoke-VPC" {
    count = "${var.spoke_count}"
    cidr_block = "${var.spoke_cidr_prefix}.${count.index}.0/24"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags {
        Name = "spoke-VPC-${var.name_suffix}-${count.index}"
    }
}

# AWS Public Subnets
resource "aws_subnet" "spoke-VPC-public" {
    count = "${var.spoke_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    cidr_block = "${var.spoke_cidr_prefix}.${count.index}.0/28"
    map_public_ip_on_launch = "true"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    tags {
        Name = "spoke-VPC-public-${var.name_suffix}-${count.index}"
    }
    timeouts {
    }
}

# AWS Public Subnets for HA
resource "aws_subnet" "spoke-VPC-public-ha" {
    count = "${var.spoke_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    cidr_block = "${var.spoke_cidr_prefix}.${count.index}.16/28"
    map_public_ip_on_launch = "true"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index+1)}"
    tags {
        Name = "spoke-VPC-public-ha-${var.name_suffix}-${count.index}"
    }
    timeouts {
    }
}

# AWS Internet GW
resource "aws_internet_gateway" "spoke-VPC-gw" {
    count = "${var.spoke_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"

    tags {
        Name = "spoke-VPC-gw-${var.name_suffix}-${count.index}"
    }
    timeouts {
    }
}

# AWS route tables
resource "aws_route_table" "spoke-VPC-route" {
    count = "${var.spoke_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${element(aws_internet_gateway.spoke-VPC-gw.*.id,count.index)}"
    }

    tags {
        Name = "spoke-VPC-route-${var.name_suffix}-${count.index}"
    }
    lifecycle {
        ignore_changes = ["route"]
    }
}

# AWS route associations public
resource "aws_route_table_association" "spoke-VPC-ra" {
    count = "${var.spoke_count}"
    subnet_id = "${element(aws_subnet.spoke-VPC-public.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.spoke-VPC-route.*.id,count.index)}"
    depends_on = ["aws_subnet.spoke-VPC-public","aws_route_table.spoke-VPC-route","aws_internet_gateway.spoke-VPC-gw","aws_vpc.spoke-VPC"]
}

# AWS route associations public HA
resource "aws_route_table_association" "spoke-VPC-ra-ha" {
    count = "${var.spoke_count}"
    subnet_id = "${element(aws_subnet.spoke-VPC-public-ha.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.spoke-VPC-route.*.id,count.index)}"
    depends_on = ["aws_subnet.spoke-VPC-public","aws_route_table.spoke-VPC-route","aws_internet_gateway.spoke-VPC-gw","aws_vpc.spoke-VPC"]
}

# Launch a spoke VPC, and join with transit VPC.
# Omit ha_subnet to launch spoke VPC without HA.
# ha_subnet can be later added or deleted to enable/disable HA in spoke VPC

resource "aviatrix_spoke_vpc" "test_spoke" {
  count = "${var.spoke_count}"
  account_name = "${var.account_name}"
  cloud_type = 1
  gw_name = "${var.name_suffix}-${count.index}"
  vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
  vpc_reg = "${var.spoke_region}"
  vpc_size = "${var.spoke_gw_size}"
  subnet = "${element(aws_subnet.spoke-VPC-public.*.cidr_block,count.index)}"
  ha_subnet = "${element(aws_subnet.spoke-VPC-public-ha.*.cidr_block,count.index)}"
  transit_gw = "${var.transit_gateway_name}"
  depends_on = ["aws_route_table_association.spoke-VPC-ra","aws_route_table_association.spoke-VPC-ra-ha",
                "aws_subnet.spoke-VPC-public","aws_subnet.spoke-VPC-public-ha",
                "aws_route_table.spoke-VPC-route","aws_internet_gateway.spoke-VPC-gw",
                "aws_vpc.spoke-VPC"]
}

# Create encrypteed peering between shared to spoke gateway

resource "aviatrix_tunnel" "shared-to-spoke"{
  count = "${var.spoke_count}"
  vpc_name1 = "${element(aviatrix_spoke_vpc.test_spoke.*.gw_name,count.index)}"
  vpc_name2 = "${var.shared_gw_name}-0"
  cluster   = "no"
  over_aws_peering = "no"
  peering_hastatus = "yes"
  enable_ha        = "yes"
  depends_on = ["aviatrix_spoke_vpc.test_spoke"]
}

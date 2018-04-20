# AWS Spoke VPCs
data "aws_availability_zones" "available" {}

resource "aws_vpc" "spoke-VPC" {
    count = "${var.vpc_count}"
    cidr_block = "${var.cidr_prefix}.${count.index}.0/24"
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
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    cidr_block = "${var.cidr_prefix}.${count.index}.0/28"
    map_public_ip_on_launch = "true"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    tags {
        Name = "spoke-VPC-public-${var.name_suffix}-${count.index}"
    }
    depends_on = ["aws_vpc.spoke-VPC"]
}

# AWS Public Subnets for HA
resource "aws_subnet" "spoke-VPC-public-ha" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    cidr_block = "${var.cidr_prefix}.${count.index}.16/28"
    map_public_ip_on_launch = "true"
    availability_zone = "${element(data.aws_availability_zones.available.names, count.index+1)}"
    tags {
        Name = "spoke-VPC-public-ha-${var.name_suffix}-${count.index}"
    }
    depends_on = ["aws_vpc.spoke-VPC"]
}

# AWS Internet GW
resource "aws_internet_gateway" "spoke-VPC-gw" {
    count = "${var.vpc_count}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"

    tags {
        Name = "spoke-VPC-gw-${var.name_suffix}-${count.index}"
    }
    depends_on = ["aws_vpc.spoke-VPC"]
}

# AWS route tables
resource "aws_route_table" "spoke-VPC-route" {
    count = "${var.vpc_count}"
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
    depends_on = ["aws_vpc.spoke-VPC"]
}

# AWS route associations public
resource "aws_route_table_association" "spoke-VPC-ra" {
    count = "${var.vpc_count}"
    subnet_id = "${element(aws_subnet.spoke-VPC-public.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.spoke-VPC-route.*.id,count.index)}"
    depends_on = ["aws_subnet.spoke-VPC-public","aws_route_table.spoke-VPC-route","aws_internet_gateway.spoke-VPC-gw","aws_vpc.spoke-VPC"]
}

# AWS route associations public HA
resource "aws_route_table_association" "spoke-VPC-ra-ha" {
    count = "${var.vpc_count}"
    subnet_id = "${element(aws_subnet.spoke-VPC-public-ha.*.id,count.index)}"
    route_table_id = "${element(aws_route_table.spoke-VPC-route.*.id,count.index)}"
    depends_on = ["aws_subnet.spoke-VPC-public","aws_route_table.spoke-VPC-route","aws_internet_gateway.spoke-VPC-gw","aws_vpc.spoke-VPC"]
}

# Launch a spoke VPC, and join with transit VPC.
# Omit ha_subnet to launch spoke VPC without HA.
# ha_subnet can be later added or deleted to enable/disable HA in spoke VPC

resource "aviatrix_spoke_vpc" "test_spoke" {
    count = "${var.vpc_count}"
    account_name = "${var.account_name}"
    cloud_type = 1
    gw_name = "${var.name_suffix}-${count.index}"
    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
    vpc_reg = "${var.region}"
    vpc_size = "${var.gw_size}"
    subnet = "${element(aws_subnet.spoke-VPC-public.*.cidr_block,count.index)}"
    ha_subnet = "${element(aws_subnet.spoke-VPC-public-ha.*.cidr_block,count.index)}"
    transit_gw = "${var.transit_gw}"
    depends_on = ["aws_route_table_association.spoke-VPC-ra","aws_route_table_association.spoke-VPC-ra-ha"]
}

### Create SPOKE Linux VM Instances
### -----------------------------------
##Spoke Linux VMs
#resource "aws_instance" "Linux" {
#    ami           = "${lookup(var.AMI, var.region)}"
#    instance_type = "${var.gw_size}"
#    count = "${var.vpc_count}"
#
#    # the VPC subnet
#    subnet_id = "${element(aws_subnet.spoke-VPC-public.*.id,count.index)}"
#
#    # the security group
#    vpc_security_group_ids = ["${aws_security_group.allow-ssh-ping-VPC.id}"]
#
#    # the public SSH key
#    key_name = "${aws_key_pair.shared_keypair.key_name}"
#
#    tags{
#      Name = "${var.name_suffix}-Linux-${var.region}"
#    } 
#    depends_on = ["aws_vpc.spoke-VPC","aws_route_table_association.spoke-VPC-ra","aws_route_table_association.spoke-VPC-ra-ha"]
#}
### END -------------------------------
## Create AWS Key Pair
### -----------------------------------
#resource "aws_key_pair" "shared_keypair" {
#    key_name = "shared_keypair"
#    public_key = "${file("${var.path_public_key}")}"
#    depends_on = ["aws_route_table_association.spoke-VPC-ra","aws_route_table_association.spoke-VPC-ra-ha"]
#}
### END -------------------------------
### Security Group Spoke Side
### -----------------------------------
#resource "aws_security_group" "allow-ssh-ping-VPC" {
#    count = "${var.vpc_count}"
#    vpc_id = "${element(aws_vpc.spoke-VPC.*.id,count.index)}"
#    name = "allow-ssh-${var.vpc_name}"
#    description = "security group that allows ssh and all egress traffic"
#    egress {
#        from_port = 0
#        to_port = 0
#        protocol = "-1"
#        cidr_blocks = ["0.0.0.0/0"]
#    }
#    ingress {
#        from_port   = 22
#        to_port     = 22
#        protocol    = "tcp"
#        cidr_blocks = ["0.0.0.0/0"]
#    }
#    ingress {
#        from_port = 0
#        to_port = 0
#        protocol = "-1"
#      cidr_blocks = ["0.0.0.0/0"]
#    }
#    tags {
#        Name = "allow-ssh-ping"
#    }
#    depends_on = ["aws_route_table_association.spoke-VPC-ra","aws_route_table_association.spoke-VPC-ra-ha"]
#}
### END -------------------------------


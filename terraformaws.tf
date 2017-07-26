provider "aws" {
	region = "us-east-1"
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
}

#VPC

resource "aws_vpc" "vpcterra" {
	cidr_block = "10.0.0.0/16"
	instance_tenancy = "default"
	enable_dns_hostnames = true
	tags {
			Name = "VPCTerra"	
	}
}

#Internet Gateway

resource "aws_internet_gateway" "internet_gateway" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	tags {
			Name = "TerraIG"	
	}
}

#Elastic IP

resource "aws_eip" "natip" {
	vpc = true
}

#NAT Gateway

resource "aws_nat_gateway" "natgw" {
	allocation_id = "${aws_eip.natip.id}"
	subnet_id = "${aws_subnet.public1.id}"
	depends_on = [ "aws_internet_gateway.internet_gateway" ]
}

#public route tabble

resource "aws_route_table" "public_rtab" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	route {
			cidr_block = "0.0.0.0/0"
			gateway_id = "${aws_internet_gateway.internet_gateway.id}"	
	}
	tags {
			Name = "PublicTerra"	
	}
}

#private route table

resource "aws_route_table" "private_rtab" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	route {
				cidr_block = "0.0.0.0/0"
				nat_gateway_id = "${aws_nat_gateway.natgw.id}"
	}
	tags {
			Name = "PrivateTerra"	
	}
}

#Subnets

resource "aws_subnet" "public1" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	cidr_block = "10.0.1.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-east-1a"
	tags {
			Name = "PublicTerra1"	
	}
}

resource "aws_subnet" "public2" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	cidr_block = "10.0.2.0/24"
	map_public_ip_on_launch = true
	availability_zone = "us-east-1b"
	tags {
			Name = "PublicTerra2"	
	}
}

resource "aws_subnet" "private1" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	cidr_block = "10.0.3.0/24"
	availability_zone = "us-east-1a"
	tags {
			Name = "PrivateTerra1"	
	}
}

resource "aws_subnet" "private2" {
	vpc_id = "${aws_vpc.vpcterra.id}"
	cidr_block = "10.0.4.0/24"
	availability_zone = "us-east-1b"
	tags {
			Name = "PrivateTerra2"	
	}
}


#Route Table Association

resource "aws_route_table_association" "public1_assoc" {
	subnet_id = "${aws_subnet.public1.id}"
	route_table_id = "${aws_route_table.public_rtab.id}"
}

resource "aws_route_table_association" "public2_assoc" {
	subnet_id = "${aws_subnet.public2.id}"
	route_table_id = "${aws_route_table.public_rtab.id}"
}

resource "aws_route_table_association" "private1_assoc" {
	subnet_id = "${aws_subnet.private1.id}"
	route_table_id = "${aws_route_table.private_rtab.id}"
}

resource "aws_route_table_association" "private2_assoc" {
	subnet_id = "${aws_subnet.private2.id}"
	route_table_id = "${aws_route_table.private_rtab.id}"
}


#Security Groups

resource "aws_security_group" "public_sec" {
	name = "sg_public"
	description = "for public subnet instances"
	vpc_id = "${aws_vpc.vpcterra.id}"
	
	#SSH
	
	ingress {
			from_port	= 22
			to_port		= 22
			protocol		= "tcp"
			cidr_blocks	= ["72.196.48.126/32"]
	}
	
	#HTTP
	
	ingress {
			from_port	= 80
			to_port		= 80
			protocol		= "tcp"
			cidr_blocks	= ["72.196.48.126/32"]
	}
	
	#HTTPS
	
	ingress {
			from_port	= 443
			to_port		= 443
			protocol		= "tcp"
			cidr_blocks	= ["72.196.48.126/32"]
	}
	
	egress {
			from_port	= 0
			to_port		= 0
			protocol		= "-1"
			cidr_blocks	= ["0.0.0.0/0"]
	}
	tags {
			Name = "TerraPublic"	
	}
	
}

resource "aws_security_group" "private_sec" {
	name = "sg_private"
	description = "for private subnet instances"
	vpc_id = "${aws_vpc.vpcterra.id}"
	
	#SSH
	
	ingress {
			from_port	= 22
			to_port		= 22
			protocol		= "tcp"
			cidr_blocks	= ["10.0.0.0/16"]
	}
	
	#HTTP
	
	ingress {
			from_port	= 80
			to_port		= 80
			protocol		= "tcp"
			cidr_blocks	= ["10.0.0.0/16"]
	}
	
	#HTTPS
	
	ingress {
			from_port	= 443
			to_port		= 443
			protocol		= "tcp"
			cidr_blocks	= ["10.0.0.0/16"]
	}
	
	egress {
			from_port	= 0
			to_port		= 0
			protocol		= "-1"
			cidr_blocks	= ["0.0.0.0/0"]
	}
	tags {
			Name = "TerraPrivate"	
	}
	
}

#Network Interfaces

resource "aws_network_interface" "net_interface1" {
	subnet_id = "${aws_subnet.public1.id}"
	security_groups = [ "${aws_security_group.public_sec.id}" ]
}

resource "aws_network_interface" "net_interface2" {
	subnet_id = "${aws_subnet.public2.id}"
	security_groups = [ "${aws_security_group.public_sec.id}" ]
}

#Bitnami Instance

resource "aws_instance" "bitnami" {
	instance_type = "t2.micro"
	ami = "ami-89f68a9f"
	key_name = "rushik-keypair"
	availability_zone = "us-east-1a"
	network_interface {
			network_interface_id	= "${aws_network_interface.net_interface1.id}"
			device_index = 0
	}
	ebs_block_device {
			device_name = "/dev/sdm"
			volume_type = "io1"
			volume_size = 10
			iops = 100
			delete_on_termination = true
	}
	tags {
			Name = "Rushik-TerraBitnami"	
	}
}

#LAMP instance

resource "aws_instance" "LAMPInstance" {
	instance_type = "t2.micro"
	ami = "ami-9e2f0988"
	key_name = "rushik-keypair"
	availability_zone = "us-east-1b"
	network_interface {
			network_interface_id	= "${aws_network_interface.net_interface2.id}"
			device_index = 0
	}
	ebs_block_device {
			device_name = "/dev/sda1"
			volume_type = "io1"
			volume_size = 10
			iops = 100
			delete_on_termination = true
	}
	user_data = "${data.template_file.user_data_shell.rendered}"
	tags {
			Name = "Rushik-TerraLAMP"	
	}
}

data "template_file" "user_data_shell" {
	template = <<-EOF
		   #!/bin/bash
		   sudo yum -y update
		   cd /home/ec2-user
		   curl -L https://www.opscode.com/chef/install.sh | sudo bash
		   sudo yum -y install git
		   sudo git clone https://github.com/rushikdesaik/chef-cft.git
		   cd chef-cft
		   sudo chef-solo -c solo.rb -j lamp.json
		   sudo echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php
		   EOF
}


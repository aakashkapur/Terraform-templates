terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}
provider "aws" {
    profile = "terraform-partners"  
    region = var.region
  }

resource "aws_vpc" "project_vpc" {
  cidr_block = var.project_cidr
  tags = {
    Name = "project-vpc"
  }
}
resource "aws_subnet" "project_public_subnet" {
  count = length(var.project_public_subnet)
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = element(var.project_public_subnet,count.index)
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "project_public_subnet_${element(data.aws_availability_zones.azs.names,count.index)}"
    "Public" = "true"
  }
}

resource "aws_subnet" "project_private_subnet" {
  count = length(var.project_private_subnet)
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = element(var.project_private_subnet,count.index)
  availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
  tags = {
    "Name" = "project_private_subnet_${element(data.aws_availability_zones.azs.names,count.index)}"
  }
}

resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    "Name" = "project_igw"
  }
}

resource "aws_route_table" "project_secondary_rt" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    "Name" = "project_secondary_rt"
  }
}

resource "aws_route" "project_secondary_rt_routes" {
  route_table_id = aws_route_table.project_secondary_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.project_igw.id
  depends_on = [
    aws_route_table.project_secondary_rt
  ]

  
}

resource "aws_route_table_association" "project_secondary_rt_association" {
  count = length(var.project_public_subnet)
  subnet_id = element(aws_subnet.project_public_subnet[*].id, count.index)
  route_table_id = aws_route_table.project_secondary_rt.id
}

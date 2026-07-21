resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# TODO(L1): public subnet 10.0.1.0/24, aws_vpc.main 참조, map_public_ip_on_launch = true
# resource "aws_subnet" "public" { ... }

# TODO(L1): internet gateway (aws_internet_gateway), vpc_id = aws_vpc.main.id
# resource "aws_internet_gateway" "gw" { ... }

# TODO(L1): route table + 0.0.0.0/0 -> igw, 그리고 subnet과 association
# resource "aws_route_table" "public" { ... }
# resource "aws_route_table_association" "public" { ... }

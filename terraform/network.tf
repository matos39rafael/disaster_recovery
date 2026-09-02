resource "aws_vpc" "principal" {
  count = var.deploy_dr ? 1 : 0

  cidr_block           = var.aws_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}_vpc_principal"
  }
}

#internet gateway
resource "aws_internet_gateway" "net_gateway" {
  count  = var.deploy_dr ? 1 : 0
  vpc_id = aws_vpc.principal[0].id

  tags = {
    Name = "${var.project_name}_internet_gateway"
  }
}

#subnet
resource "aws_subnet" "public_subnet" {
  count                   = var.deploy_dr ? 1 : 0
  vpc_id                  = aws_vpc.principal[0].id
  cidr_block              = var.public_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}_vpc_principal_public_subnet"
  }
}

#route table
resource "aws_route_table" "public" {
  count  = var.deploy_dr ? 1 : 0
  vpc_id = aws_vpc.principal[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.net_gateway[0].id
  }

}

#route table association
resource "aws_route_table_association" "public" {
  count          = var.deploy_dr ? 1 : 0
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public[0].id
}


#--------------------------------------------------------------------------------------------
#Creating VPC 
#--------------------------------------------------------------------------------------------
resource "aws_vpc" "tokigames_vpc" {
  cidr_block                                        = var.vpc_cidr_block
  enable_dns_support                                = true
  enable_dns_hostnames                              = true

  tags = {
    Name                                            = "${var.vpc_tag_name}-${var.env}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

#--------------------------------------------------------------------------------------------
# Create the private subnet
#--------------------------------------------------------------------------------------------
resource "aws_subnet" "private_subnet" {
  vpc_id                                            = aws_vpc.tokigames_vpc.id
  cidr_block                                        = var.private_subnet_cidr_block

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = 1
  }
}

#--------------------------------------------------------------------------------------------
# Create the public subnet
#--------------------------------------------------------------------------------------------
resource "aws_subnet" "public_subnet" {
  count                                             = length(var.availability_zones)
  vpc_id                                            = aws_vpc.tokigames_vpc.id
  cidr_block                                        = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone                                 = element(var.availability_zones, count.index)

  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = 1
  }

  map_public_ip_on_launch                           = true
}

#--------------------------------------------------------------------------------------------
# Create IGW for the public subnets
#--------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id                                            = aws_vpc.tokigames_vpc.id
}

#--------------------------------------------------------------------------------------------
# Route the public subnet traffic through the IGW
#--------------------------------------------------------------------------------------------
resource "aws_route_table" "main" {
  vpc_id                                            = aws_vpc.tokigames_vpc.id

  route {
    cidr_block                                      = "0.0.0.0/0"
    gateway_id                                      = aws_internet_gateway.igw.id
  }

  tags = {
    Name                                            = "${var.route_table_tag_name}-${var.env}"
  }
}

#--------------------------------------------------------------------------------------------
# Route table and subnet associations
#--------------------------------------------------------------------------------------------
resource "aws_route_table_association" "internet_access" {
  count                                             = length(var.availability_zones)
  subnet_id                                         = aws_subnet.public_subnet[count.index].id
  route_table_id                                    = aws_route_table.main.id
}

#--------------------------------------------------------------------------------------------
# ECR Endpoint Service
#--------------------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name                                      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_id                                            = aws_vpc.tokigames_vpc.id
  vpc_endpoint_type                                 = "Interface"
  subnet_ids                                        = flatten([aws_subnet.public_subnet.*.id])
  private_dns_enabled                               = true
  security_group_ids                                = [aws_security_group.ecr_endpoint_sg.id]
							                        
  tags = {                                          
    Name                                            = "ECR Docker VPC Endpoint Interface - ${var.env} "
    Environment                                     = var.env
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id                                            = aws_vpc.tokigames_vpc.id
  service_name                                      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type                                 = "Interface"
  private_dns_enabled                               = true
  subnet_ids                                        = flatten([aws_subnet.public_subnet.*.id])
  security_group_ids                                = [aws_security_group.ecr_endpoint_sg.id]
							                        
  tags = {                                          
    Name                                            = "ECR API VPC Endpoint Interface - ${var.env}"
    Environment                                     = var.env
  }
}

#--------------------------------------------------------------------------------------------
# EC2 Endpoint Service
#--------------------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "ec2" {
  vpc_id                                            = aws_vpc.tokigames_vpc.id
  service_name                                      = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type                                 = "Interface"
  private_dns_enabled                               = true
  subnet_ids                                        = flatten([aws_subnet.public_subnet.*.id])
  security_group_ids                                = [aws_security_group.ec2_endpoint_sg.id]
							                        
  tags = {                                          
    Name                                            = "EC2 VPC Endpoint Interface - ${var.env}"
    Environment                                     = var.env
  }
}

#--------------------------------------------------------------------------------------------
# S3 Endpoint Service
#--------------------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id                                           = aws_vpc.tokigames_vpc.id
  service_name                                     = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type                                = "Gateway"
  route_table_ids                                  = [aws_route_table.main.id]
							                       
  tags = {                                         
    Name                                           = "S3 VPC Endpoint Gateway"
    Environment                                    = var.env
  }
}

#--------------------------------------------------------------------------------------------
# EC2 VPC Endpoint security groups
#--------------------------------------------------------------------------------------------
resource "aws_security_group" "ec2_endpoint_sg" {
  name                                             = "EC2-EndPoint-SG"
  vpc_id                                           = aws_vpc.tokigames_vpc.id
}

resource "aws_security_group_rule" "endpoint_ec2_https" {
  security_group_id                                = aws_security_group.ec2_endpoint_sg.id
  type                                             = "ingress"
  from_port                                        = 443
  to_port                                          = 443
  protocol                                         = "tcp"
  cidr_blocks                                      = flatten([[var.private_subnet_cidr_block], var.public_subnet_cidr_blocks])
}

#--------------------------------------------------------------------------------------------
# ECR VPC Endpoint security groups
#--------------------------------------------------------------------------------------------
resource "aws_security_group" "ecr_endpoint_sg" {
  name                                             = "ECR-EndPoint-SG"
  vpc_id                                           = aws_vpc.tokigames_vpc.id
}

resource "aws_security_group_rule" "endpoint_ecr_https" {
  security_group_id                                = aws_security_group.ecr_endpoint_sg.id
  type                                             = "ingress"
  from_port                                        = 443
  to_port                                          = 443
  protocol                                         = "tcp"
  cidr_blocks                                      = flatten([[var.private_subnet_cidr_block], var.public_subnet_cidr_blocks])
}
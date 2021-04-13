#--------------------------------------------------------------------------------------------
# Variables
#--------------------------------------------------------------------------------------------
variable "vpc_tag_name" {
  type        = string
  description = "Name tag for the VPC"
}

variable "route_table_tag_name" {
  type        = string
  default     = "main"
  description = "Route table description"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.200.0.0/16"
  description = "CIDR block range for vpc"
}

variable "private_subnet_cidr_block" {
  type        = string
  default     = "10.200.0.0/24"
  description = "CIDR block range for the private subnet"
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
  default     = ["10.200.1.0/24", "10.200.2.0/24"]
  description = "CIDR block range for the public subnet"
}

variable "env" {
  type        = string
  description = "Application enviroment"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type = string
}

variable "availability_zones" {
  type  = list(string)
  default = ["us-west-1a", "us-west-1c"]
  description = "List of availability zones for the selected region"
}

variable "region" {
  description = "aws region to deploy to"
  type        = string
}

#--------------------------------------------------------------------------------------------
# OutPuts
#--------------------------------------------------------------------------------------------
output vpc_arn {
  value = aws_vpc.tokigames_vpc.arn
}

output vpc_id {
  value = aws_vpc.tokigames_vpc.id
}

output private_subnet_id {
  value = aws_subnet.private_subnet.id
}

output public_subnet_ids {
  value = aws_subnet.public_subnet.*.id
}
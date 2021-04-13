
#--------------------------------------------------------------------------------------------
# Provider Section
#--------------------------------------------------------------------------------------------

provider "aws" {
  
  region                     = var.region
  assume_role {
    role_arn                 = var.role_arn
  }
}


terraform {
  backend "s3" {
    bucket                    = "tokigames-nonprod-state"
	key                       = "tfstate/us-west-1/tokigames-np.tfstate"
    region                    = "us-west-1"
	}
}

#--------------------------------------------------------------------------------------------
# VPC for EKS
#--------------------------------------------------------------------------------------------
module "vpc_for_eks_core" {
  source                      = "./aws_vpc"
  
  eks_cluster_name            = var.eks_cluster_name
  vpc_tag_name                = "${var.platform}-vpc"
  route_table_tag_name        = "${var.platform}-rt"
  region                      = var.region
  env                         = var.env
}

# EKS Cluster Creation Module
module "eks_cluster_core" {
  source                      = "./aws_eks_cluster"
  
  # Cluster specific
  vpc_id                      = module.vpc_for_eks_core.vpc_id
  cluster_sg_name             = "${var.platform}-cluster-sg"
  nodes_sg_name               = "${var.platform}-node-sg"
  eks_cluster_name            = var.eks_cluster_name
  eks_cluster_subnet_ids      = module.vpc_for_eks_core.public_subnet_ids
  private_desired_size        = 3
  private_max_size            = 8
  private_min_size            = 2
  public_desired_size         = 1
  public_max_size             = 2
  public_min_size             = 1
  endpoint_private_access     = true
  endpoint_public_access      = true
  
  # Node group specific
  node_group_name             = "${var.eks_cluster_name}-node-group"
  private_subnet_ids          = [module.vpc_for_eks_core.private_subnet_id]
  public_subnet_ids           = module.vpc_for_eks_core.public_subnet_ids
  environment                 = var.env
}
variable "module" {
  description = "Terraform module used to deploy"
  type        = string
}

variable "role_arn" {
  description = "AWS IAM RoleArn"
  type        = string
}

variable "region" {
  description = "aws region to deploy to"
  type        = string
}

variable "platform" {
  description = "The name of the platform"
  type = string
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type = string
}

variable "env" {
  description = "Applicaiton environment"
  type = string
}
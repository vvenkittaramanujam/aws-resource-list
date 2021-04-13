#--------------------------------------------------------------------------------------------
# Creating EKS Worker Node Groups
#--------------------------------------------------------------------------------------------
resource "aws_eks_node_group" "eks_cluster_main" {
  cluster_name                  = aws_eks_cluster.eks_cluster_main.name
  node_group_name               = var.node_group_name
  node_role_arn                 = aws_iam_role.eks_nodes_roles.arn
  subnet_ids                    = var.private_subnet_ids

  ami_type                      = var.ami_type
  disk_size                     = var.disk_size
  instance_types                = var.instance_types
  scaling_config {
    desired_size                = var.private_desired_size
    max_size                    = var.private_max_size
    min_size                    = var.private_min_size
  }

  tags = {
    Name                        = var.node_group_name
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecs_read_only
  ]
}

resource "aws_eks_node_group" "public" {
  cluster_name                  = aws_eks_cluster.eks_cluster_main.name
  node_group_name               = "${var.node_group_name}-public"
  node_role_arn                 = aws_iam_role.eks_nodes_roles.arn
  subnet_ids                    = var.public_subnet_ids

  ami_type                      = var.ami_type
  disk_size                     = var.disk_size
  instance_types                = var.instance_types

  scaling_config {
    desired_size                = var.public_desired_size
    max_size                    = var.public_max_size
    min_size                    = var.public_min_size
  }

  tags = {
    Name                       = "${var.node_group_name}-public"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecs_read_only,
  ]
}
#--------------------------------------------------------------------------------------------
#Creating EKS Worker Node IAM Role
#--------------------------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodes_roles" {

  name                  = "${var.eks_cluster_name}-worker-${var.environment}"
  assume_role_policy    = data.aws_iam_policy_document.eks_nodes_policy.json
}

data "aws_iam_policy_document" "eks_nodes_policy" {
  statement {
    effect              = "Allow"

    actions             = ["sts:AssumeRole"]

    principals {
      type              = "Service"
      identifiers       = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn            = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role                  = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn            = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role                  = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "ecs_read_only" {
  policy_arn            = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role                  = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn            = aws_iam_policy.cluster_autoscaler_policy.arn
  role                  = aws_iam_role.eks_nodes_roles.name
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name                  = "ClusterAutoScaler"
  description           = "Providing the worker node running the Cluster Autoscaler access to required resources and actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
#--------------------------------------------------------------------------------------------
#Creating EKS Worker Node Security Groups
#--------------------------------------------------------------------------------------------
resource "aws_security_group" "eks_nodes_sg" {
  name                          = var.nodes_sg_name
  description                   = "Security group for all nodes in the cluster"
  vpc_id                        = var.vpc_id

  egress {
    from_port                   = 0
    to_port                     = 0
    protocol                    = "-1"
    cidr_blocks                 = ["0.0.0.0/0"]
  }

  tags = {
    Name                        = var.nodes_sg_name
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "nodes" {
  description                   = "Allow nodes to communicate with each other"
  from_port                     = 0
  protocol                      = "-1"
  security_group_id             = aws_security_group.eks_nodes_sg.id
  source_security_group_id      = aws_security_group.eks_nodes_sg.id
  to_port                       = 65535
  type                          = "ingress"
}

resource "aws_security_group_rule" "nodes_inbound" {
  description                   = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                     = 1025
  protocol                      = "tcp"
  security_group_id             = aws_security_group.eks_nodes_sg.id
  source_security_group_id      = aws_security_group.eks_cluster_sg.id
  to_port                       = 65535
  type                          = "ingress"
}
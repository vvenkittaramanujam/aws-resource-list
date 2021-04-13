#--------------------------------------------------------------------------------------------
# IAM Role for provisioning
#--------------------------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodes_iam" {
  assume_role_policy    = data.aws_iam_policy_document.eks_nodes_iam.json
  name                  = "eks-alb-ingress-controller"
}

# Policy document for trust relationship
data "aws_iam_policy_document" "eks_nodes_iam" {
  statement {
    effect              = "Allow"
    actions             = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test              = "StringEquals"
      variable          = "${replace(aws_iam_openid_connect_provider.eks_cluster_main_connection.url, "https://", "")}:sub"
      values            = ["system:serviceaccount:kube-system:alb-ingress-controller"]
    }

    principals {
      identifiers       = [aws_iam_openid_connect_provider.eks_cluster_main_connection.arn]
      type              = "Federated"
    }
  }
}

#data "tls_certificate" "cluster" {
#  url                   = aws_eks_cluster.eks_cluster_main.identity.0.oidc.0.issuer
#}
#
#resource "aws_iam_openid_connect_provider" "eks_nodes_iam" {
#  client_id_list        = ["sts.amazonaws.com"]
#  thumbprint_list       = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint], [])
#  url                   = aws_eks_cluster.eks_cluster_main.identity.0.oidc.0.issuer
#}

#--------------------------------------------------------------------------------------------
# IAM role and policy attachment
#--------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_nodes_iam" {
  role                  = aws_iam_role.eks_nodes_iam.name
  policy_arn            = aws_iam_policy.eks_nodes_iam.arn
}

#--------------------------------------------------------------------------------------------
# ALB Ingress Controller policy
#--------------------------------------------------------------------------------------------
resource "aws_iam_policy" "eks_nodes_iam" {
  name                  = "ALBIngressControllerIAMPolicy"
  description           = "EKS ALB Ingress Controller"
  policy                = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "acm:DescribeCertificate",
            "acm:ListCertificates",
            "acm:GetCertificate"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:DeleteTags",
            "ec2:DeleteSecurityGroup",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVpcs",
            "ec2:ModifyInstanceAttribute",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:RevokeSecurityGroupIngress"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:RemoveTags",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:SetWebACL"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "iam:CreateServiceLinkedRole",
            "iam:GetServerCertificate",
            "iam:ListServerCertificates"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "cognito-idp:DescribeUserPoolClient"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "waf-regional:GetWebACLForResource",
            "waf-regional:GetWebACL",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "tag:GetResources",
            "tag:TagResources"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "waf:GetWebACL"
         ],
         "Resource":"*"
      }
   ]
}
EOF
}
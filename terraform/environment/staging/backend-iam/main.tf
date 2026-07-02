data "terraform_remote_state" "database" {
  backend = "s3"
  config = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
  key = "staging/eks-infra/database/terraform.tfstate", region = "us-east-1" }
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = { bucket = "cloudnorth-tf-state-acav-aws-account-main"
  key = "staging/eks-infra/eks/terraform.tfstate", region = "us-east-1" }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name   # this output exists + isn't sensitive
}


locals {
  table_arn = data.terraform_remote_state.database.outputs.dynamodb_table_arn
  oidc_issuer_url   = data.aws_eks_cluster.this.identity[0].oidc[0].issuer  
  oidc_provider     = replace(local.oidc_issuer_url, "https://", "")     
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
}

resource "aws_iam_policy" "backend_ddb" {
  name = "backend-dynamodb-staging"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Query",
        "dynamodb:UpdateItem", "dynamodb:DeleteItem",
        "dynamodb:BatchGetItem", "dynamodb:BatchWriteItem",
        "dynamodb:Scan"
      ]
      Resource = [
        local.table_arn,
        "${local.table_arn}/index/*" # the type-index GSI
      ]
    }]
  })
}

resource "aws_iam_role" "backend" {
  name = "backend-app-staging"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backend" {
  role       = aws_iam_role.backend.name
  policy_arn = aws_iam_policy.backend_ddb.arn
}

# resource "aws_eks_pod_identity_association" "backend" {
#   cluster_name    = "eks-infra-staging"
#   namespace       = "app"
#   service_account = "backend"
#   role_arn        = aws_iam_role.backend.arn
# }

resource "aws_iam_role" "irsa_iam_role" {
  name = "backend-app-irsa-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = local.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:sub" = "system:serviceaccount:app:backend"
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "backend_irsa" {
  role       = aws_iam_role.irsa_iam_role.name
  policy_arn = aws_iam_policy.backend_ddb.arn
}
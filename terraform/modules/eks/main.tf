# main.tf — EKS control plane, CloudWatch logging, and OIDC (IRSA foundation)
#
# The control plane is managed by AWS. Worker nodes are defined in node-group.tf.

# -----------------------------------------------------------------------------
# Locals and data sources
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  base_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Module      = "eks"
    },
    var.additional_tags
  )

  # Cluster ENIs must span multiple AZs; include public subnets when provided
  cluster_subnet_ids = distinct(concat(var.private_subnet_ids, var.public_subnet_ids))

  # Explicit version wins; otherwise use the EKS default Kubernetes version in this region
  cluster_version = coalesce(
    var.kubernetes_version,
    one([for v in data.aws_eks_cluster_versions.available.cluster_versions : v.cluster_version if v.default_version])
  )
}

data "aws_eks_cluster_versions" "available" {
  default_only = true
}

# -----------------------------------------------------------------------------
# CloudWatch Logs — control plane logs (api, audit, authenticator, etc.)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = merge(
    local.base_tags,
    {
      Name = "${var.cluster_name}-cluster-logs"
    }
  )
}

# -----------------------------------------------------------------------------
# EKS cluster
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = local.cluster_version

  vpc_config {
    subnet_ids              = local.cluster_subnet_ids
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.cluster_endpoint_private_access
    public_access_cidrs     = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(
    local.base_tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy,
    aws_cloudwatch_log_group.cluster,
  ]
}

# -----------------------------------------------------------------------------
# OIDC provider — required for IRSA (IAM Roles for Service Accounts)
# -----------------------------------------------------------------------------

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(
    local.base_tags,
    {
      Name = "${var.cluster_name}-oidc"
    }
  )
}

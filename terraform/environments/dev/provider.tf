# provider.tf — Terraform version, providers, and optional remote backend
#
# Run all commands from this directory: terraform/environments/dev

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 7.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # profile = "terraform-sessions"

  # Provider default_tags — merged onto supported AWS resources automatically
  default_tags {
    tags = local.common_tags
  }
}

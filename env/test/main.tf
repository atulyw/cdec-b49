provider "aws" {
  profile = "terraform-sessions"
  region  = "eu-west-1"
}


module "vpc" {
  source = "../../modules/vpc"
  application = var.application
  env = var.env
  vpc_cidr = var.vpc_cidr
  private_subnet = var.private_subnet
  public_subnet = var.public_subnet
  tags = var.tags
}


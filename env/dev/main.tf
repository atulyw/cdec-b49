provider "aws" {
  profile = "terraform-sessions"
  region  = "eu-west-1"
}


module "vpc" {
  source              = "../../modules/vpc"
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]
  public_subnet_cidr  = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zone   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  tags = {
    application = "iata"
    environment = "dev"
    owner       = "john.doe"
  }
}

output "public-subnet" {
  value = module.vpc.public-subnet-ids
}
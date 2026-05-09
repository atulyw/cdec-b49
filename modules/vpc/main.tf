resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = var.instance_tenancy
  tags = {
    Name = format("%s-%s-vpc", var.application, var.environment)
    environment = var.environment
    owner = var.owner
  }
}


resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id     = resource.aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]

  tags = {
    Name = "${var.application}-${var.environment}-private-subnet-${var.private_subnet_cidr[count.index]}"
  }
}  

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id     = resource.aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]

  tags = {
    Name = "${var.application}-${var.environment}-public-subnet-${var.public_subnet_cidr[count.index]}"
  }
}  


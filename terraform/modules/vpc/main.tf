# main.tf — VPC networking for Amazon EKS
#
# Flow: VPC → subnets (public + private per AZ) → IGW → NAT → route tables → associations
# EKS uses public subnets for internet-facing load balancers and private subnets for nodes.

# -----------------------------------------------------------------------------
# Locals — derived maps so we can use for_each instead of count
# -----------------------------------------------------------------------------

locals {
  # Common tags on every resource (dynamic merge with caller-provided tags)
  base_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Module      = "vpc-eks"
    },
    var.additional_tags
  )

  # EKS requires subnet tags so the cloud controller knows where to place ELBs
  eks_cluster_tag_key = "kubernetes.io/cluster/${var.cluster_name}"

  # Build a map: AZ name -> { cidr, tier } for clean for_each keys
  public_subnets = {
    for idx, az in var.availability_zones : az => {
      az   = az
      cidr = var.public_subnet_cidrs[idx]
    }
  }

  private_subnets = {
    for idx, az in var.availability_zones : az => {
      az   = az
      cidr = var.private_subnet_cidrs[idx]
    }
  }

  # First AZ is used when single_nat_gateway = true (NAT lives in a public subnet)
  first_az = var.availability_zones[0]

  # Naming prefix keeps resources identifiable in the AWS console
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.base_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

# -----------------------------------------------------------------------------
# Internet Gateway — allows public subnets to reach the internet
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.base_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

# -----------------------------------------------------------------------------
# Public subnets — typically ALB/NLB and NAT Gateway placement
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true # Instances get a public IP (needed for NAT ENI path)

  tags = merge(
    local.base_tags,
    {
      Name                        = "${local.name_prefix}-public-${each.key}"
      Tier                        = "public"
      "kubernetes.io/role/elb"    = "1"
      (local.eks_cluster_tag_key) = "shared"
    }
  )
}

# -----------------------------------------------------------------------------
# Private subnets — EKS worker nodes and internal load balancers
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  # No map_public_ip_on_launch — nodes stay off the public internet

  tags = merge(
    local.base_tags,
    {
      Name                              = "${local.name_prefix}-private-${each.key}"
      Tier                              = "private"
      "kubernetes.io/role/internal-elb" = "1"
      (local.eks_cluster_tag_key)       = "shared"
    }
  )
}

# -----------------------------------------------------------------------------
# Elastic IP — stable public IP for the NAT Gateway
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  for_each = var.single_nat_gateway ? toset([local.first_az]) : toset(var.availability_zones)

  domain = "vpc"

  tags = merge(
    local.base_tags,
    {
      Name = var.single_nat_gateway ? "${local.name_prefix}-nat-eip" : "${local.name_prefix}-nat-eip-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------------------------------------
# NAT Gateway — outbound internet from private subnets (pull images, patches)
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "this" {
  for_each = var.single_nat_gateway ? toset([local.first_az]) : toset(var.availability_zones)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? local.first_az : each.key].id

  tags = merge(
    local.base_tags,
    {
      Name = var.single_nat_gateway ? "${local.name_prefix}-nat" : "${local.name_prefix}-nat-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------------------------------------
# Public route table — default route to Internet Gateway
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    local.base_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Private route table(s) — default route to NAT Gateway
# -----------------------------------------------------------------------------

resource "aws_route_table" "private" {
  for_each = var.single_nat_gateway ? toset(["default"]) : toset(var.availability_zones)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[local.first_az].id : aws_nat_gateway.this[each.key].id
  }

  tags = merge(
    local.base_tags,
    {
      Name = var.single_nat_gateway ? "${local.name_prefix}-private-rt" : "${local.name_prefix}-private-rt-${each.key}"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = var.single_nat_gateway ? aws_route_table.private["default"].id : aws_route_table.private[each.key].id
}

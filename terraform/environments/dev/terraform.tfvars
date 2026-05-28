# DEV environment — cost-optimized sizing for development and learning
# Naming: <project>-<environment>-<resource> e.g. cdec-dev-eks

aws_region   = "eu-west-1"
environment  = "dev"
project_name = "alpha"
cluster_name = "alpha-dev-eks"

# DEV VPC — separate CIDR from future test (10.20.x) / prod (10.30.x) to allow peering later
vpc_cidr = "10.10.0.0/16"

public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.20.0/24"]

availability_zones = ["eu-west-1a", "eu-west-1b"]

# Cost: single NAT (~$32/month + data transfer) vs NAT per AZ
single_nat_gateway = true

# EKS — latest stable when null; pin version in test/prod for change control
kubernetes_version = null

node_instance_types = ["c7i-flex.large"]
desired_size        = 2
min_size            = 1
max_size            = 3
disk_size           = 50

cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

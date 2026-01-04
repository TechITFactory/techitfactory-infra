# =============================================================================
# VPC MODULE - IMPLEMENTATION
# =============================================================================
#
# PURPOSE:
# Creates a production-ready VPC with public and private subnets for EKS.
#
# ARCHITECTURE:
# ┌─────────────────────────────────────────────────────────────┐
# │                          VPC (10.0.0.0/16)                   │
# │  ┌──────────────────┐      ┌──────────────────┐            │
# │  │  Public Subnet   │      │  Public Subnet   │            │
# │  │  10.0.1.0/24     │      │  10.0.2.0/24     │            │
# │  │  (AZ-A)          │      │  (AZ-B)          │            │
# │  │  - ALB           │      │  - ALB           │            │
# │  │  - NAT Gateway   │      │                  │            │
# │  └────────┬─────────┘      └──────────────────┘            │
# │           │                                                  │
# │  ┌────────▼─────────┐      ┌──────────────────┐            │
# │  │  Private Subnet  │      │  Private Subnet  │            │
# │  │  10.0.10.0/24    │      │  10.0.20.0/24    │            │
# │  │  (AZ-A)          │      │  (AZ-B)          │            │
# │  │  - EKS Nodes     │      │  - EKS Nodes     │            │
# │  └──────────────────┘      └──────────────────┘            │
# └─────────────────────────────────────────────────────────────┘
#
# RESOURCES CREATED:
# - VPC with DNS hostnames enabled
# - Internet Gateway
# - 2 Public Subnets (for ALB, NAT)
# - 2 Private Subnets (for EKS nodes)
# - 1 or 2 NAT Gateways (configurable)
# - Route Tables (public + private)
# - S3 VPC Endpoint (optional, FREE)
# - Interface Endpoints (optional, for ECR/Logs/STS)
# =============================================================================

locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Module      = "vpc"
      Environment = var.environment
    },
    var.tags
  )
}

# Get current AWS region
data "aws_region" "current" {}

# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for EKS
  enable_dns_support   = true # Required for EKS

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })
}

# =============================================================================
# INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name}-igw"
  })
}

# =============================================================================
# PUBLIC SUBNETS
# =============================================================================

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                     = "${local.name}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb" = "1" # Tag for ALB Controller
    Tier                     = "public"
  })
}

# =============================================================================
# PRIVATE SUBNETS
# =============================================================================

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(local.common_tags, {
    Name                              = "${local.name}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1" # Tag for internal ALB
    Tier                              = "private"
  })
}

# =============================================================================
# ELASTIC IP FOR NAT GATEWAY
# =============================================================================

resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# NAT GATEWAY
# =============================================================================

resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : length(var.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# PUBLIC ROUTE TABLE
# =============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# PRIVATE ROUTE TABLES
# =============================================================================

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# =============================================================================
# S3 VPC ENDPOINT (Gateway - FREE)
# =============================================================================

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(local.common_tags, {
    Name = "${local.name}-s3-endpoint"
  })
}

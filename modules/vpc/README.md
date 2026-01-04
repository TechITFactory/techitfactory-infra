# VPC Module

Creates a production-ready VPC with public/private subnets for EKS.

## Architecture

```
┌─────────────────────────────────────────┐
│                 VPC                      │
│  ┌─────────────┐  ┌─────────────┐       │
│  │   Public    │  │   Public    │       │
│  │  Subnet A   │  │  Subnet B   │       │
│  │  (ALB)      │  │  (ALB)      │       │
│  └──────┬──────┘  └─────────────┘       │
│         │ NAT                            │
│  ┌──────▼──────┐  ┌─────────────┐       │
│  │  Private    │  │  Private    │       │
│  │  Subnet A   │  │  Subnet B   │       │
│  │ (EKS Nodes) │  │ (EKS Nodes) │       │
│  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────┘
```

## Features

- Multi-AZ deployment (2 AZs)
- Public subnets for ALB
- Private subnets for EKS nodes
- Single NAT Gateway (cost-optimized for dev)
- S3 VPC Endpoint (free, reduces NAT costs)

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "techitfactory"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = true
  enable_s3_endpoint = true
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | required |
| environment | Environment (dev/prod) | string | required |
| vpc_cidr | VPC CIDR block | string | 10.0.0.0/16 |
| azs | Availability zones | list | ap-south-1a, 1b |
| single_nat_gateway | Use single NAT | bool | true |
| enable_s3_endpoint | Enable S3 endpoint | bool | true |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| private_subnet_ids | Private subnet IDs (for EKS) |
| public_subnet_ids | Public subnet IDs (for ALB) |
| nat_public_ips | NAT Gateway public IPs |

## Cost Optimization

| Configuration | Monthly Cost |
|--------------|--------------|
| Single NAT Gateway | ~$32 |
| NAT per AZ (2) | ~$64 |
| S3 Gateway Endpoint | FREE |

## Status

🔲 **Skeleton** - Full implementation in Story 3.1

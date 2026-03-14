# EKS Module

Creates a production-ready EKS cluster with managed node groups.

## Architecture

```
┌─────────────────────────────────────────┐
│           EKS Control Plane              │
│         (AWS Managed - Free)             │
└────────────────┬────────────────────────┘
                 │ OIDC
┌────────────────▼────────────────────────┐
│          Managed Node Group              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ t3.med  │ │ t3.med  │ │  ...    │   │
│  └─────────┘ └─────────┘ └─────────┘   │
└─────────────────────────────────────────┘
```

## Features

- EKS 1.28 with OIDC for IRSA
- Managed Node Group (t3.medium)
- Cluster Autoscaler support
- EBS CSI Driver for PVs
- CloudWatch logging

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  project_name = "techitfactory"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids

  cluster_version   = "1.28"
  node_desired_size = 2
  node_min_size     = 1
  node_max_size     = 4
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_name | Project name | string | required |
| environment | Environment | string | required |
| vpc_id | VPC ID | string | required |
| subnet_ids | Subnet IDs for nodes | list | required |
| cluster_version | K8s version | string | 1.28 |
| node_instance_types | Instance types | list | t3.medium |
| node_desired_size | Desired nodes | number | 2 |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_endpoint | API endpoint |
| cluster_oidc_issuer_url | OIDC URL for IRSA |
| kubeconfig_command | Command to configure kubectl |

## IRSA (IAM Roles for Service Accounts)

This module creates OIDC provider for IRSA. Example usage:

```hcl
# In your application module
module "app_irsa" {
  source = "../../modules/irsa"

  oidc_provider_arn = module.eks.oidc_provider_arn
  namespace         = "app"
  service_account   = "my-app"
  policy_arns       = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}
```

## Cost Estimate (Dev)

| Resource | Monthly Cost |
|----------|--------------|
| EKS Control Plane | $72 |
| 2x t3.medium nodes | $60 |
| EBS volumes (50GB each) | $10 |
| **Total** | **~$142/month** |

## Status

🔲 **Skeleton** - Full implementation in Story 4.1

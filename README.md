# TechIT Factory - Infrastructure

Terraform code for AWS infrastructure.

## Structure

```
├── bootstrap/          # S3 state, DynamoDB lock, KMS
├── modules/
│   ├── vpc/           # VPC, subnets, NAT
│   └── eks/           # EKS cluster, node groups
├── environments/
│   ├── dev/           # Dev environment
│   └── prod/          # Prod environment
└── .github/workflows/ # Terraform CI/CD
```

## Branching Model
- `main` → Protected, requires PR
- Feature branches → Short-lived, <1 day

## Quick Start

```bash
# Dev environment
cd environments/dev
terraform init
terraform plan
terraform apply
```

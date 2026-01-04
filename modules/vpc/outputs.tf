# =============================================================================
# VPC MODULE - OUTPUTS
# =============================================================================
#
# PURPOSE:
# Expose VPC resources for use by other modules (EKS, ALB, etc.)
#
# CONSUMERS:
# - EKS Module: Needs private_subnet_ids for node placement
# - ALB Controller: Needs public_subnet_ids for load balancers
# - Security Groups: Need vpc_id for association
# =============================================================================

# -----------------------------------------------------------------------------
# VPC OUTPUTS
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

# -----------------------------------------------------------------------------
# SUBNET OUTPUTS
# -----------------------------------------------------------------------------

output "private_subnet_ids" {
  description = "Private subnet IDs (for EKS nodes)"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

# -----------------------------------------------------------------------------
# GATEWAY OUTPUTS
# -----------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "NAT Gateway public IPs (for allowlisting)"
  value       = aws_eip.nat[*].public_ip
}

# -----------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
# -----------------------------------------------------------------------------

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = aws_route_table.private[*].id
}

# -----------------------------------------------------------------------------
# VPC ENDPOINT OUTPUTS
# -----------------------------------------------------------------------------

output "s3_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

# -----------------------------------------------------------------------------
# AVAILABILITY ZONE OUTPUTS
# -----------------------------------------------------------------------------

output "azs" {
  description = "Availability zones used"
  value       = var.azs
}

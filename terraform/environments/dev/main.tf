locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
}

# ==============================================================================
# 1. Networking (VPC, Public, Private App, and Private DB Subnets)
# ==============================================================================
module "networking" {
  source = "../../modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  cluster_name             = local.cluster_name
}

# ==============================================================================
# 2. Internet Gateway
# ==============================================================================
module "internet_gateway" {
  source = "../../modules/internet-gateway"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

# ==============================================================================
# 3. NAT Gateway
# ==============================================================================
module "nat_gateway" {
  source = "../../modules/nat-gateway"

  project_name       = var.project_name
  environment        = var.environment
  public_subnet_ids  = module.networking.public_subnet_ids
  single_nat_gateway = var.single_nat_gateway
}

# ==============================================================================
# 4. Route Tables
# ==============================================================================
module "route_tables" {
  source = "../../modules/route-tables"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  internet_gateway_id    = module.internet_gateway.internet_gateway_id
  public_subnet_ids      = module.networking.public_subnet_ids
  nat_gateway_ids        = module.nat_gateway.nat_gateway_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
}

# ==============================================================================
# 5. Security Groups (Least-Privilege Cross-Tier Rules)
# ==============================================================================
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr_block
  db_port      = var.db_port
}

# ==============================================================================
# 6. VPC Endpoints (Private AWS Backbone Access)
# ==============================================================================
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  vpc_id               = module.networking.vpc_id
  subnet_ids           = module.networking.private_app_subnet_ids
  route_table_ids      = module.route_tables.private_app_route_table_ids
  security_group_ids   = [module.security_groups.vpc_endpoints_security_group_id]
  enable_vpc_endpoints = var.enable_vpc_endpoints
}

# ==============================================================================
# 7. EKS Control Plane
# ==============================================================================
module "eks" {
  source = "../../modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  cluster_name              = local.cluster_name
  cluster_version           = var.cluster_version
  cluster_log_types         = var.cluster_log_types
  vpc_id                    = module.networking.vpc_id
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
}

# ==============================================================================
# 8. EKS Managed Node Groups (Strictly in Private Subnets)
# ==============================================================================
module "eks_node_groups" {
  source = "../../modules/eks-node-groups"

  project_name                = var.project_name
  environment                 = var.environment
  cluster_name                = module.eks.cluster_name
  cluster_version             = var.cluster_version
  private_app_subnet_ids      = module.networking.private_app_subnet_ids
  eks_nodes_security_group_id = module.security_groups.eks_nodes_security_group_id
  instance_types              = var.eks_instance_types
  ami_type                    = var.eks_ami_type
  desired_size                = var.eks_desired_size
  min_size                    = var.eks_min_size
  max_size                    = var.eks_max_size
}

# ==============================================================================
# 9. IAM & IRSA Roles (AWS Load Balancer Controller & Secrets Reader)
# ==============================================================================
module "iam" {
  source = "../../modules/iam"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

# ==============================================================================
# 10. Amazon ECR Repositories (Scan on Push & Lifecycle Rules)
# ==============================================================================
module "ecr" {
  source = "../../modules/ecr"

  repository_names = var.ecr_repository_names
  scan_on_push     = true
  max_image_count  = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==============================================================================
# 11. S3 Buckets (Frontend Static Assets & Access Logs)
# ==============================================================================
module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# ==============================================================================
# 12. CloudFront CDN (Private S3 Origin with OAC & Dynamic ALB Routing)
# ==============================================================================
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name                   = var.project_name
  environment                    = var.environment
  s3_bucket_id                   = module.s3.frontend_bucket_id
  s3_bucket_arn                  = module.s3.frontend_bucket_arn
  s3_bucket_regional_domain_name = module.s3.frontend_bucket_regional_domain_name
  custom_domain_name             = ""
  acm_certificate_arn            = ""
  alb_dns_name                   = module.alb.alb_dns_name
}

# ==============================================================================
# 13. Application Load Balancer (Public HTTP Entrypoint behind CloudFront)
# ==============================================================================
module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  enable_https          = false
  acm_certificate_arn   = ""
  enable_access_logs    = false
  logs_bucket_id        = module.s3.logs_bucket_id
}

# ==============================================================================
# 16. AWS Secrets Manager (Secure Database Credentials)
# ==============================================================================
module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment
  db_username  = var.db_username
  db_name      = var.db_name
}

# ==============================================================================
# 17. Amazon RDS (Strictly Private Database Tier)
# ==============================================================================
module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  private_db_subnet_ids   = module.networking.private_db_subnet_ids
  rds_security_group_id   = module.security_groups.rds_security_group_id
  db_name                 = module.secrets_manager.db_name
  db_username             = module.secrets_manager.db_username
  db_password             = module.secrets_manager.db_password
  instance_class          = var.db_instance_class
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
}

# ==============================================================================
# 18. CloudWatch Monitoring & Metric Alarms
# ==============================================================================
module "monitoring" {
  source = "../../modules/monitoring"

  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = module.eks.cluster_name
  alb_arn_suffix       = module.alb.alb_arn_suffix
  db_instance_id       = module.rds.db_instance_id
  enable_rds_alarm     = true
  enable_alb_alarm     = true
  create_eks_log_group = var.create_eks_log_group
}

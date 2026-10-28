# Networking
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs (EKS nodes/workloads)"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs (RDS)"
  value       = module.networking.private_db_subnet_ids
}

# EKS
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure local kubectl context"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "aws_lb_controller_role_arn" {
  description = "IAM Role ARN to annotate the AWS Load Balancer Controller service account"
  value       = module.iam.aws_lb_controller_role_arn
}

# Ingress / ALB & CloudFront
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution serving the React frontend"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for automated cache invalidations"
  value       = module.cloudfront.distribution_id
}

output "frontend_s3_bucket" {
  description = "Private S3 bucket name for frontend static build assets"
  value       = module.s3.frontend_bucket_id
}

# Database
output "rds_endpoint" {
  description = "Private connection endpoint for the RDS database"
  value       = module.rds.db_instance_endpoint
}

output "rds_secret_arn" {
  description = "AWS Secrets Manager ARN storing database master credentials"
  value       = module.secrets_manager.secret_arn
}

# Container Repositories
output "ecr_repository_urls" {
  description = "Map of ECR repository URLs for pushing microservice Docker images"
  value       = module.ecr.repository_urls
}

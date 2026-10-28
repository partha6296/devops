output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.networking.private_db_subnet_ids
}

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

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
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

output "rds_endpoint" {
  description = "Private connection endpoint for the RDS database"
  value       = module.rds.db_instance_endpoint
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.repository_urls
}

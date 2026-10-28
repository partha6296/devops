variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops-taskapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (EKS nodes/workloads)"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (RDS)"
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]
}

variable "single_nat_gateway" {
  description = "Deploy a single NAT gateway or multiple for HA"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Whether to provision VPC Endpoints"
  type        = bool
  default     = true
}

variable "cluster_version" {
  description = "EKS Kubernetes version (supported: 1.34, 1.35, 1.36, 1.37)"
  type        = string
  default     = "1.34"
}

variable "eks_instance_types" {
  description = "Instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 6
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "taskmanagement"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgresadmin"
}

variable "db_instance_class" {
  description = "RDS database instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_port" {
  description = "Database port (5432 for Postgres)"
  type        = number
  default     = 5432
}

variable "ecr_repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default = [
    "taskapp-user-service",
    "taskapp-task-service",
    "taskapp-notification-service",
    "taskapp-frontend"
  ]
}

variable "create_custom_domain_records" {
  description = "Whether to create custom ACM and Route 53 records"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "staging.example.com"
}

variable "frontend_domain_name" {
  description = "Custom domain for the frontend SPA"
  type        = string
  default     = ""
}

variable "api_domain_name" {
  description = "Custom domain for the backend API"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Existing Route 53 Hosted Zone ID"
  type        = string
  default     = ""
}

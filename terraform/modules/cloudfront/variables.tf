variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the frontend S3 bucket"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the frontend S3 bucket"
  type        = string
}

variable "custom_domain_name" {
  description = "Optional custom domain name (e.g., app.example.com)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN in us-east-1 for custom domain HTTPS"
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "Optional DNS name of the Application Load Balancer to route /api/* traffic"
  type        = string
  default     = ""
}

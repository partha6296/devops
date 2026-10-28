variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (supported: 1.34, 1.35, 1.36, 1.37)"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "VPC ID where EKS is created"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "List of private application subnet IDs for EKS control plane and ENIs"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "List of desired control plane logging to enable"
  type        = list(string)
  default     = []
}

project_name = "cloudops-taskapp"
environment  = "prod"
aws_region   = "us-east-1"

vpc_cidr           = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs      = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_app_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
private_db_subnet_cidrs  = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

single_nat_gateway   = false # Highly available (1 NAT Gateway per AZ)
enable_vpc_endpoints = true

cluster_version    = "1.34"
eks_instance_types = ["m5.large"]
eks_desired_size   = 3
eks_min_size       = 3
eks_max_size       = 10

db_name                    = "taskmanagement"
db_username                = "postgresadmin"
db_instance_class          = "db.m6g.large"
db_multi_az                = true # Multi-AZ High Availability
db_backup_retention_period = 30
db_port                    = 5432

create_custom_domain_records = false # Set to true when domain is active

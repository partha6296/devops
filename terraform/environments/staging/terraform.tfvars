project_name = "cloudops-taskapp"
environment  = "staging"
aws_region   = "us-east-1"

vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_app_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
private_db_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

single_nat_gateway   = false # High availability across AZs
enable_vpc_endpoints = true

cluster_version    = "1.34"
eks_instance_types = ["t3.medium"]
eks_desired_size   = 2
eks_min_size       = 2
eks_max_size       = 6

db_name           = "taskmanagement"
db_username       = "postgresadmin"
db_instance_class = "db.t4g.medium"
db_multi_az       = false
db_port           = 5432

create_custom_domain_records = false

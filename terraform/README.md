# Production-Grade AWS Infrastructure Using Terraform & EKS

This repository contains the enterprise, production-grade Infrastructure as Code (IaC) for deploying containerized microservices and static frontends on Amazon Web Services (AWS) using **Terraform**, **Amazon EKS**, and **Amazon RDS**.

---

## 🏛️ Architecture Overview

The infrastructure enforces a strict **3-Tier Network Isolation Architecture** following the AWS Well-Architected Framework:

```mermaid
flowchart TD
    User["Public Internet Users"]

    subgraph Edge["Edge Layer (Global)"]
        CF["Amazon CloudFront (CDN)"]
        S3["Private S3 Bucket (Vite/React Static Assets)"]
        OAC["Origin Access Control (OAC)"]
        CF -->|Signed SigV4| OAC --> S3
    end

    subgraph VPC["AWS VPC (10.0.0.0/16 across 3 Availability Zones)"]
        subgraph PublicTier["Tier 1: Public Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)"]
            ALB["Internet-Facing Application Load Balancer"]
            NAT["Managed NAT Gateways"]
            IGW["Internet Gateway"]
        end

        subgraph PrivateAppTier["Tier 2: Private Application Subnets (10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24)"]
            EKS_CP["Amazon EKS Control Plane (1.34, KMS Encrypted)"]
            subgraph EKS_Nodes["EKS Managed Node Groups (IMDSv2 Enforced)"]
                PodAuth["User / Auth Pods (:3001)"]
                PodTask["Task Pods (:3002)"]
                PodNotif["Notification Pods (:3003)"]
                PodFront["Frontend API Gateway (:3000)"]
            end
            VPCE["VPC Endpoints (ECR, S3, STS, CloudWatch, SecretsManager)"]
        end

        subgraph PrivateDBTier["Tier 3: Private Database Subnets (10.0.21.0/24, 10.0.22.0/24, 10.0.23.0/24)"]
            RDS[("Amazon RDS PostgreSQL (Multi-AZ, Storage Encrypted)")]
        end
    end

    User -->|1. HTTPS app.example.com| CF
    User -->|2. HTTPS api.example.com| ALB
    ALB -->|3. Target Type: IP (Pod IPs)| EKS_Nodes
    PodTask -->|4. Internal ClusterIP| PodAuth & PodNotif
    PodTask & PodAuth -->|5. Port 5432 (Isolated)| RDS
    EKS_Nodes -->|6. Outbound Internet| NAT --> IGW
    EKS_Nodes -->|7. AWS API Traffic (Private)| VPCE
```

---

## 📁 Modular Directory Structure

```text
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf                 # Orchestrates all modules for development
│   │   ├── variables.tf            # Configurable inputs (cost-optimized sizing)
│   │   ├── terraform.tfvars        # Single NAT GW, single-AZ RDS, t3.medium EKS
│   │   ├── outputs.tf              # Kubectl config commands, endpoints, ECR URLs
│   │   └── backend.tf              # Remote S3 state + locking config
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars        # Multi-AZ NAT GWs, pre-prod sizing
│   │   ├── outputs.tf
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars        # High Availability: Multi-AZ RDS, 3 NAT GWs, m5.large nodes
│       ├── outputs.tf
│       └── backend.tf
│
├── modules/
│   ├── networking/                 # VPC, 3 Subnet Tiers across 3 AZs (Public, Private-App, Private-DB)
│   ├── internet-gateway/           # AWS Internet Gateway for public subnet routing
│   ├── nat-gateway/                # Managed NAT Gateways & Elastic IPs (single or multi-AZ)
│   ├── route-tables/               # Route tables & associations for each tier
│   ├── security-groups/            # Least-privilege security groups with zero public DB access
│   ├── vpc-endpoints/              # Interface & Gateway endpoints (S3, ECR, CloudWatch, STS, Secrets)
│   ├── eks/                        # EKS Control Plane, KMS envelope encryption, OIDC provider
│   ├── eks-node-groups/            # Managed Node Groups in private subnets with IMDSv2 launch templates
│   ├── iam/                        # IRSA roles (AWS Load Balancer Controller & Secrets Manager reader)
│   ├── ecr/                        # Container repositories with scan-on-push & lifecycle rules
│   ├── s3/                         # Private frontend static asset bucket & access logs bucket
│   ├── cloudfront/                 # CloudFront distribution with Origin Access Control (OAC) & SPA fallback
│   ├── acm/                        # Public SSL/TLS certificates via AWS Certificate Manager
│   ├── route53/                    # DNS A-record aliases pointing to CloudFront and ALB
│   ├── alb/                        # Internet-facing Application Load Balancer with HTTP-to-HTTPS redirect
│   ├── rds/                        # Private PostgreSQL/MySQL with KMS encryption & automated backups
│   ├── secrets-manager/            # Secure database credentials generated & stored in AWS Secrets Manager
│   └── monitoring/                 # CloudWatch log groups, metric alarms, and SNS topic
│
└── README.md
```

---

## 🚦 End-to-End Request Flow & Ingress Path

1. **Frontend Request**:
   - The user navigates to `https://app.example.com`.
   - **CloudFront** serves static Vite/React assets cached at the nearest Edge location.
   - For cache misses, CloudFront signs requests using **Origin Access Control (OAC)** to fetch from the private S3 bucket. Direct public access to S3 is blocked (`BlockPublicAccess = true`).
2. **Backend API Request**:
   - The browser issues REST requests to `https://api.example.com/api/...`.
   - Route 53 resolves the domain to the **Application Load Balancer** in the public subnets.
   - The ALB terminates TLS using the **ACM Certificate** and forwards traffic.
3. **AWS Load Balancer Controller & Target Type: IP**:
   - Instead of routing to NodePorts through `kube-proxy`, the AWS Load Balancer Controller uses **Target Type: `ip`**.
   - The ALB targets the private IP addresses of the application pods directly via the AWS VPC CNI.
4. **Microservice Inter-Communication**:
   - Pods communicate with companion microservices inside the cluster using native Kubernetes `ClusterIP` DNS names (e.g. `http://user-service:80`).
5. **Database Queries**:
   - Pods query the Amazon RDS instance in the **Private Database Subnet**.
   - The RDS Security Group strictly accepts inbound traffic on port 5432 from the **EKS Node Security Group** only.

---

## 🔒 Security Best Practices Implemented

| Security Pillar | Implementation |
| :--- | :--- |
| **Network Isolation** | 3-tier subnets. EKS worker nodes and RDS instances have **no public IP addresses** and no route to the Internet Gateway. |
| **Secrets Encryption** | EKS Secrets are encrypted at rest using a dedicated customer-managed **AWS KMS Key**. |
| **Database Credentials** | Passwords are generated via `random_password`, stored in **AWS Secrets Manager**, and never hardcoded in Terraform or Git. |
| **SSRF Protection** | EC2 Launch Templates enforce **IMDSv2** (`http_tokens = "required"`, `http_put_response_hop_limit = 2`). |
| **Zero Static AWS Keys** | EKS pods assume IAM roles dynamically via **OIDC and IRSA** (IAM Roles for Service Accounts). |
| **S3 Hardening** | Public ACLs and Policies are blocked on all buckets. CloudFront accesses S3 solely via SigV4 OAC policies. |

---

## 🛠️ Step-by-Step Deployment Instructions

### Prerequisites
- AWS CLI configured with administrator credentials.
- Terraform `>= 1.5.0` installed.

### 1. Initialize and Validate
```bash
cd terraform/environments/dev

# Format all files
terraform fmt -recursive ../../

# Initialize providers and child modules
terraform init

# Validate configuration syntax
terraform validate
```

### 2. Plan and Review Resources
```bash
terraform plan -out=tfplan
```

### 3. Apply the Infrastructure
```bash
terraform apply tfplan
```

### 4. Connect to the EKS Cluster
The Terraform output generates the exact `update-kubeconfig` command:
```bash
aws eks --region us-east-1 update-kubeconfig --name cloudops-taskapp-dev-eks

# Verify nodes are running in private subnets
kubectl get nodes -o wide
```

---

## 💰 Cost Optimization by Environment

| Environment | NAT Gateways | RDS Deployment | EKS Compute | Estimated Monthly Cost |
| :--- | :--- | :--- | :--- | :--- |
| **`dev`** | 1 (Single NAT) | Single-AZ (`db.t4g.medium`) | 2x `t3.medium` | ~\$120 - \$160 |
| **`staging`** | 2 (Multi-AZ) | Single-AZ (`db.t4g.medium`) | 2x `t3.medium` | ~\$190 - \$240 |
| **`prod`** | 3 (1 per AZ) | Multi-AZ (`db.m6g.large`) | 3x `m5.large` | ~\$480 - \$620 |

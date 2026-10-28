# ==============================================================================
# 1. IAM Role for EKS Worker Nodes
# ==============================================================================
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-node-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# AWS Systems Manager Core policy for secure SSH-less bastion access
resource "aws_iam_role_policy_attachment" "node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# ==============================================================================
# 2. Hardened EC2 Launch Template (IMDSv2 Enforced)
# ==============================================================================
resource "aws_launch_template" "node" {
  name_prefix   = "${var.cluster_name}-lt-"
  instance_type = var.instance_types[0]

  vpc_security_group_ids = [var.eks_nodes_security_group_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 mandatory to prevent SSRF
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                                        = "${var.cluster_name}-node"
      Environment                                 = var.environment
      Project                                     = var.project_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# 3. EKS Managed Node Group in Private Subnets
# ==============================================================================
resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-managed-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_app_subnet_ids
  capacity_type   = var.capacity_type
  ami_type        = var.ami_type
  version         = var.cluster_version

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = var.environment
    NodePool    = "general-compute"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_registry,
    aws_iam_role_policy_attachment.node_ssm
  ]

  tags = {
    Name        = "${var.cluster_name}-managed-nodes"
    Environment = var.environment
    Project     = var.project_name
  }
}

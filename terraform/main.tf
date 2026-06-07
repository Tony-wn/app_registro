terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto en S3 + bloqueo con DynamoDB (requerido por la rúbrica)
  backend "s3" {
    bucket         = "proyecto-devops-tfstate-app-registro"
    key            = "app-registro/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-app-registro"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "app-registro"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true   # Cost-effective para proyecto universitario

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ─────────────────────────────────────────
# EKS Cluster
# ─────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    app = {
      instance_types = ["t3.small"]   # Free tier compatible
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

# ─────────────────────────────────────────
# S3 para estado de Terraform (bootstrap)
# ─────────────────────────────────────────
resource "aws_s3_bucket" "tfstate" {
  bucket = "proyecto-devops-tfstate-app-registro"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────
# DynamoDB para bloqueo de estado
# ─────────────────────────────────────────
resource "aws_dynamodb_table" "tflock" {
  name         = "terraform-lock-app-registro"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster EKS"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "ID del VPC"
  value       = module.vpc.vpc_id
}

output "s3_tfstate_bucket" {
  description = "Bucket S3 para el estado de Terraform"
  value       = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_lock_table" {
  description = "Tabla DynamoDB para el bloqueo de estado"
  value       = aws_dynamodb_table.tflock.name
}

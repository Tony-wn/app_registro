variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
  default     = "app-registro"
}

variable "cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "app-registro-eks"
}

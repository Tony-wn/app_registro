# Este archivo se usa con: terraform init -backend-config=backend.tf
# NO committear si contiene credenciales reales

bucket         = "proyecto-devops-tfstate-app-registro"
key            = "app-registro/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-lock-app-registro"

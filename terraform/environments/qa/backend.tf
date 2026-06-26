terraform {
  backend "s3" {
    bucket         = "devops-app-tfstate-ap-south-1"
    key            = "qa/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "devops-app-tfstate-lock"
  }
}

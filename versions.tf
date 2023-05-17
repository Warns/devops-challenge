terraform {
  required_version = ">= 1.1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
  }

  backend "s3" {
    key     = "tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region      = "eu-west-1"
  max_retries = 10
}

## Create backend
#resource "aws_s3_bucket" "terraform_backend_bucket" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  bucket = module.this.id
#}
#
#resource "aws_s3_bucket_versioning" "versioning_example" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  bucket = aws_s3_bucket.terraform_backend_bucket[0].id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}
#
#resource "aws_dynamodb_table" "terraform_backend_lock_table" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  name         = module.this.id
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}
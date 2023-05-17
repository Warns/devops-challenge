terraform {
  required_version = ">= 0.14.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
  }
}

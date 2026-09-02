terraform {
  required_version = ">= 1.15.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.61.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.24.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = "disater_recovery"
      Enviroment = "lab"
      ManagedBy  = "terraform"
    }
  }

}

provider "cloudflare" {

}

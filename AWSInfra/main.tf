terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_s3_bucket" "bronze" {
  bucket = "landing-zone-p64"

  force_destroy = true
  tags = {
    Owner = var.owner_name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "silver" {
  bucket = "refined-zone-p64"
  force_destroy = true
  tags = {
    Owner = var.owner_name
    Environment = "Dev"
  }
}
resource "aws_s3_bucket" "gold" {
  bucket = "curated-zone-p64"
  force_destroy = true
  tags = {
    Owner = var.owner_name
    Environment = "Dev"
  }
}





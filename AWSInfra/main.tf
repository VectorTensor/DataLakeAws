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

resource "aws_s3_bucket" "athena_results" {
  bucket = "my-athena-query-results-p64"
  force_destroy = true
  tags = {
    Owner = var.owner_name
    Environment = "Dev"
  }
}


resource "aws_iam_role" "athena_role" {
  name = "athena-query-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "athena_s3_access" {
  name        = "AthenaS3AccessPolicy"
  description = "Allows Athena to read from S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "${aws_s3_bucket.gold.arn}",
        "${aws_s3_bucket.gold.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "${aws_s3_bucket.athena_results.arn}/*"
    }
  ]
}
EOF
}
resource "aws_glue_crawler" "athena_crawler" {
  name          = "athena-s3-crawler"
  database_name = aws_glue_catalog_database.athena_db.name
  role          = aws_iam_role.athena_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.gold.bucket}/"
  }

}
resource "aws_iam_role_policy_attachment" "athena_attach" {
  role       = aws_iam_role.athena_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "athena_attach_S3" {
  role       = aws_iam_role.athena_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "athena_attach_crawler" {
  role       = aws_iam_role.athena_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}
resource "aws_glue_catalog_database" "athena_db" {
  name = "athena_database"
}

resource "aws_athena_workgroup" "athena_wg" {
  name = "athena_curated_query"
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}




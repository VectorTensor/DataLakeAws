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
  bucket = "cleaned-zone-p64"
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

# data "aws_ami" "ubuntu_ami" {
#
#   most_recent = true
#   owners = ["amazon"]
#   filter {
#     name = "name"
#     values = ["ubuntu*"]
#   }
#
# }
#
# resource "aws_instance" "dev" {
#   ami = data.aws_ami.ubuntu_ami.id
#   instance_type = "t2.micro"
#   subnet_id = "subnet-0f7da863d6389517c"
#   tags = {
#     Owner = var.owner_name
#   }
# }
# IAM Role for Lambda
resource "aws_iam_role" "lambda_etl_role" {
  name = "LambdaETLPermissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "LambdaETLPermissions"
  }
}

resource "aws_iam_role_policy_attachment" "etl_lambda" {

  role = aws_iam_role.lambda_etl_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"

}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_etl_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda function
resource "aws_lambda_function" "etl_lambda" {
  function_name    = "etl_lambda"
  runtime         = "python3.9"  # Change runtime if needed
  role            = aws_iam_role.lambda_etl_role.arn
  handler         = "hello.lambda_handler"
  timeout         = 30

  # Path to the ZIP package of the Lambda function
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
  environment  {
    variables = {

      DEST_BUCKET = aws_s3_bucket.silver.bucket
    }
  }
  tags = {
    Name = "ETL Lambda Function"
  }
}

# Optional: Add S3 trigger for Lambda
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bronze.arn
}

resource "aws_s3_bucket_notification" "s3_lambda_trigger" {
  bucket = aws_s3_bucket.bronze.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_lambda.arn
    events             = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}



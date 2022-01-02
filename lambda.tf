terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.1.2"

  backend "s3" {
    bucket = "040489059668-bucket"
    key    = "lambda"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "iam_lambda" {
  for_each = local.ws_settings.lambda
  name     = "iam-${each.key}-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  for_each         = local.ws_settings.lambda
  filename         = "./target/${each.key}.jar"
  function_name    = "${each.key}-${terraform.workspace}"
  role             = aws_iam_role.iam_lambda[each.key].arn
  handler          = each.value.handler
  source_code_hash = filebase64sha256("./target/${each.key}.jar")
  runtime          = "java8"

  environment {
    variables = each.value.environment
  }
}

locals {
  ws_path     = "./workspace/${terraform.workspace}.yml"
  ws_raw      = fileexists(local.ws_path) ? file(local.ws_path) : yamldecode({})
  ws_settings = yamldecode(local.ws_raw)
}
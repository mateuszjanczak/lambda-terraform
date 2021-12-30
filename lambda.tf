terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = "> 1.1.2"

  backend "s3" {
    bucket = "040489059668-bucket"
    key    = "weather_check_lambda"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_iam_role" "iam_weather_check_lambda" {
  name = "iam_weather_check_lambda"

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

resource "aws_lambda_function" "weather_check_lambda" {
  filename         = "weather_check_lambda.zip"
  function_name    = "weather_check_lambda"
  role             = aws_iam_role.iam_weather_check_lambda.arn
  handler          = "com.serverless.Handler"
  source_code_hash = filebase64sha256("weather_check_lambda.zip")
  runtime          = "java8"

  environment {
    variables = {
      API_URL = "https://api.openweathermap.org/data/2.5/weather?q=%CITY%&appid=%APIKEY%&units=metric",
      API_KEY = "749561a315b14523a8f5f1ef95e45864"
    }
  }
}
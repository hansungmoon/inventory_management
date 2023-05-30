# sales Lambda 생성을 위한 리소스
resource "aws_lambda_function" "sales_api" {
  function_name    = "sales-api"
  filename         = data.archive_file.lambda_zip_file2.output_path
  source_code_hash = data.archive_file.lambda_zip_file2.output_base64sha256
  handler          = "handler.handler"
  role             = aws_iam_role.sales_lambda_role.arn
  runtime          = "nodejs14.x"
  environment {
    variables = {
      TOPIC_ARN = module.sns_topic.sns_topic_arn,
      DB_HOSTNAME  = var.DB_HOSTNAME,
      DB_USERNAME  = var.DB_USERNAME,
      DB_PASSWORD  = var.DB_PASSWORD,
      DB_DATABASE  = var.DB_DATABASE,
      DB_PORT = var.DB_PORT
    }
  }
}

# 소스파일 zip 압축
data "archive_file" "lambda_zip_file2" {
  type        = "zip"
  source_dir  = "${path.module}/sales-api"
  output_path = "${path.module}/sales-api.zip"
}

# API_GATEWAY 
# 모듈로 생성
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${aws_lambda_function.sales_api.function_name}"
  description   = "My awesome HTTP API Gateway"
  protocol_type = "HTTP"

  integrations = {
    "$default" = {
      lambda_arn             = aws_lambda_function.sales_api.arn
      payload_format_version = "2.0" # Payload 
    }
  }

  create_api_domain_name = false # to control creation of API Gateway Domain Name
  # create_default_stage             = false # to control creation of "$default" stage
  # create_default_stage_api_mapping = false # to control creation of "$default" stage and API mapping

  tags = {
    Name = "http-apigateway"
  }
}

# 람다 트리거 연결하는 리소스
# Attach API Gateway to Lambda 
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sales_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*"
}

# 람다 ROLE 생성
resource "aws_iam_role" "sales_lambda_role" {
  name               = "sales_lambda_role"
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

# 람다에 넣을 SNS 정책 생성
# Create Policy Lambda to SNS
data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      module.sns_topic.sns_topic_arn
    ]
  }
}

# 위에서 작성한 정책을 기반으로 정책 resource생성
# Policy Convert to JSON
resource "aws_iam_policy" "lambda_SNS_policy" {
  name   = "lambda_SNS_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

# 위에서 작성된 IAM ROLE을 정책에 연결
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment1" {
  role       = aws_iam_role.sales_lambda_role.name
  policy_arn = aws_iam_policy.lambda_SNS_policy.arn
}

# 람다에 연결할 정책 리소스 생성
resource "aws_iam_policy" "sales_lambda_policy" {   
  name        = "sales_lambda_policy"
  path        = "/"
  description = "Policy for sqs to lambda demo"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
      ],
      "Resource": [
                "arn:aws:logs:ap-northeast-2:725601756882:log-group:/aws/lambda/sales-apis:*:*",
                "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.sales_api.function_name}:*"
            ]
    }
  ]
}
EOF
}

# 위에서 작성된 IAM ROLE을 정책에 연결
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment2" {
  role       = aws_iam_role.sales_lambda_role.name
  policy_arn = aws_iam_policy.sales_lambda_policy.arn
}

# CloudWatch Log group 생성
# CloudWatch Log group to store Lambda logs
resource "aws_cloudwatch_log_group" "sales_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.sales_api.function_name}"
  retention_in_days = 14
}


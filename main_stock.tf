## Stock Lambda는 리소스를 이용해서 생성함.

# 현재 호출자, ID 값을 가져오기 위한 데이터
data "aws_caller_identity" "current" {}

# 현재 사용중인 Region 정보를 가져오기 위한 데이터
data "aws_region" "current" {}

# Stock Lambda 생성을 위한 리소스
resource "aws_lambda_function" "stock_lambda" {
  function_name    = "stock"
  filename         = data.archive_file.lambda_zip_file.output_path
  # filename         = "${path.module}/stock_lambda.zip"
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  handler          = "index.handler"
  role             = aws_iam_role.stock_lambda_role.arn
  runtime          = "nodejs14.x"
  environment {
    variables = {
      factory_ENDPOINT   = var.factory_ENDPOINT,
      callback_ENDPOINT = module.api_gateway_increase.apigatewayv2_api_api_endpoint
    }
  }
}

# 소스파일 zip 압축
data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_dir  = "${path.module}/aws-node-project"
  output_path = "${path.module}/stock_lambda.zip"
}

# Role to execute lambda
resource "aws_iam_role" "stock_lambda_role" {
  name               = "stock_lambda_role"
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

# CloudWatch Log group to store Lambda logs
resource "aws_cloudwatch_log_group" "stock_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.stock_lambda.function_name}"
  retention_in_days = 14
}

# Custom policy to read SQS queue and write to CloudWatch Logs with least privileges
resource "aws_iam_policy" "stock_lambda_policy" {   
  name        = "stock_lambda_policy"
  path        = "/"
  description = "Policy for sqs to lambda demo"
  policy      = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.stock_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.stock_lambda.function_name}:*:*"
    }
  ]
}
EOF
}

# 위에서 작성된 IAM ROLE을 정책에 연결
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.stock_lambda_role.name
  policy_arn = aws_iam_policy.stock_lambda_policy.arn
}

# 이벤트 소스 매핑
resource "aws_lambda_event_source_mapping" "sqs_lambda_source_mapping" {
  event_source_arn = aws_sqs_queue.stock_queue.arn
  function_name    = aws_lambda_function.stock_lambda.function_name
}
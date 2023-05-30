# ## Sales Lambda는 module을 이용해서 생성함.

# # Lambda 선언
# module "lambda" {
#   source  = "terraform-aws-modules/lambda/aws"
#   version = "3.3.1"
#   # insert the 32 required variables here
#   function_name = "sales-apis"
#   description   = "My awesome lambda function"
#   handler       = "handler.handler"
#   runtime       = "nodejs14.x"
#   timeout       = 6

#   environment_variables = {
#     TOPIC_ARN = module.sns_topic.sns_topic_arn
#     HOSTNAME  = var.DB_HOSTNAME
#     USERNAME  = var.DB_USERNAME
#     PASSWORD  = var.DB_PASSWORD
#     DATABASE  = var.DB_DATABASE
#   }

#   source_path                   = "./sales-api"
#   attach_cloudwatch_logs_policy = true
#   # create_package         = false
#   # local_existing_package = "./sales-api.zip"

#   tags = {
#     Name = "sales-api"
#   }
# }


# # API_GATEWAY 
# # 모듈로 생성
# module "api_gateway" {
#   source = "terraform-aws-modules/apigateway-v2/aws"

#   name          = "${module.lambda.lambda_function_name}-API"
#   description   = "My awesome HTTP API Gateway"
#   protocol_type = "HTTP"

#   integrations = {
#     "$default" = {
#       lambda_arn             = module.lambda.lambda_function_arn
#       payload_format_version = "2.0" # Payload 
#     }
#   }

#   create_api_domain_name = false # to control creation of API Gateway Domain Name
#   # create_default_stage             = false # to control creation of "$default" stage
#   # create_default_stage_api_mapping = false # to control creation of "$default" stage and API mapping

#   tags = {
#     Name = "http-apigateway"
#   }
# }

# # 람다 트리거 연결하는 리소스
# # Attach API Gateway to Lambda 
# resource "aws_lambda_permission" "api_gw" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda.lambda_function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*"
# }

# # Create Policy Lambda to SNS
# data "aws_iam_policy_document" "lambda_policy_document" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "sns:Publish"
#     ]
#     resources = [
#       module.sns_topic.sns_topic_arn
#     ]
#   }
# }

# # Policy Convert to JSON
# resource "aws_iam_policy" "lambda_SNS_policy" {
#   name   = "lambda_SNS_policy"
#   path   = "/"
#   policy = data.aws_iam_policy_document.lambda_policy_document.json
# }

# # Policy Connect
# resource "aws_iam_policy_attachment" "attach_lambda_iam_policy" {
#   name       = "lambda-policy-attachment"
#   roles      = [module.lambda.lambda_role_name]
#   policy_arn = aws_iam_policy.lambda_SNS_policy.arn
# }


# ## SNS 리소스 생성 
# ## SNS 토픽 발행
# module "sns_topic" {
#   source  = "terraform-aws-modules/sns/aws"
#   version = "~> 3.0"

#   name = "stock_empty2"
# }



# resource "aws_sqs_queue" "stock_queue" {
#   name                      = "stock_queue_2"
#   delay_seconds             = 0
#   max_message_size          = 256000
#   message_retention_seconds = 345600
#   receive_wait_time_seconds = 0
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.stock_queue_deadletter.arn
#     maxReceiveCount     = 4
#   })
# }

# # SQS DLQ 생성
# resource "aws_sqs_queue" "stock_queue_deadletter" {
#   name                      = "stock_queue_2_dlq"
#   delay_seconds             = 0
#   max_message_size          = 256000
#   message_retention_seconds = 345600
#   receive_wait_time_seconds = 0
# }

# # SNS 구독 SNS -> SQS
# resource "aws_sns_topic_subscription" "sqs_target" {
#   topic_arn = module.sns_topic.sns_topic_arn
#   protocol  = "sqs"
#   endpoint  = aws_sqs_queue.stock_queue.arn
# }

# # SNS to SQS 정책 생성
# resource "aws_sqs_queue_policy" "sns_sqs_sqspolicy" {
#   queue_url = aws_sqs_queue.stock_queue.id
#   policy    = <<EOF
# {
#   "Version": "2012-10-17",
#   "Id": "sns_sqs_policy",
#   "Statement": [
#     {
#       "Sid": "Allow SNS publish to SQS",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "sns.amazonaws.com"
#       },
#       "Action": "sqs:SendMessage",
#       "Resource": "${aws_sqs_queue.stock_queue.arn}",
#       "Condition": {
#         "ArnEquals": {
#           "aws:SourceArn": "${module.sns_topic.sns_topic_arn}"
#         }
#       }
#     }
#   ]
# }
# EOF
# }

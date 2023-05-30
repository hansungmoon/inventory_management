output "api_gateway_endpoint" {
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
  description = "The URI of the API."
}

output "lambda_function_name" {
  value       = aws_lambda_function.sales_api.function_name
  description = "The name of the Lambda Function"
}

output "sns_topic_name" {
  value       = module.sns_topic.sns_topic_name
  description = "NAME of SNS topic"
}

output "sqs_queue_name" {
  value       = aws_sqs_queue.stock_queue.arn
  description = "The URL for the created Amazon SQS queue."
}

output "api_gateway_info" {
  value       = module.api_gateway_increase
  description = "api_gateway_info"
}

# output "sqs_queue_url" {
#   value = aws_sqs_queue.sqs_lambda_demo_queue.url
# }

# output "sqs_queue_arn" {
#   value = aws_sqs_queue.sqs_lambda_demo_queue.arn
# }

# output "lambda_function_name" {
#   value = aws_lambda_function.sqs_lambda_demo_function.function_name
# }

# output "cloudwatch_log_group" {
#   value = aws_cloudwatch_log_group.sqs_lambda_demo_loggroup.name
# }
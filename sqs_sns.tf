## SNS 리소스 생성 
## SNS 토픽 발행
module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name = "stock_empty2"
}



resource "aws_sqs_queue" "stock_queue" {
  name                      = "stock_queue_2"
  delay_seconds             = 0
  max_message_size          = 256000
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.stock_queue_deadletter.arn
    maxReceiveCount     = 4
  })
}

# SQS DLQ 생성
resource "aws_sqs_queue" "stock_queue_deadletter" {
  name                      = "stock_queue_2_dlq"
  delay_seconds             = 0
  max_message_size          = 256000
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0
}

# SNS 구독 SNS -> SQS
resource "aws_sns_topic_subscription" "sqs_target" {
  topic_arn = module.sns_topic.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.stock_queue.arn
}

# SNS to SQS 정책 생성
resource "aws_sqs_queue_policy" "sns_sqs_sqspolicy" {
  queue_url = aws_sqs_queue.stock_queue.id
  policy    = <<EOF
{
  "Version": "2012-10-17",
  "Id": "sns_sqs_policy",
  "Statement": [
    {
      "Sid": "Allow SNS publish to SQS",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.stock_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${module.sns_topic.sns_topic_arn}"
        }
      }
    }
  ]
}
EOF
}
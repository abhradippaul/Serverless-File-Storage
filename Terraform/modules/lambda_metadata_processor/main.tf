locals {
  source_dir = abspath(var.source_path)
}

# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = substr("${var.function_name}-exec-role", 0, 64)
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query"
    ]

    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.function_name}_dynamodb_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

data "aws_iam_policy_document" "lambda_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [var.sqs_arn]
  }
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name   = "${var.function_name}_sqs_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_sqs.json
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn        = var.sqs_arn
  function_name           = aws_lambda_function.this.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 5
  }

  depends_on = [aws_iam_role_policy.lambda_sqs]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Package the Python Lambda function code into a zip archive
data "archive_file" "this" {
  type        = "zip"
  source_file = "${local.source_dir}/main.py"
  output_path = "${local.source_dir}/function.zip"
}

# Lambda function
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.this.output_base64sha256
  architectures    = [var.architecture]
  memory_size      = var.memory_size
  timeout          = var.timeout

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda_basic_execution
  ]

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowSQSEventSource"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = var.sqs_arn

  depends_on = [aws_lambda_event_source_mapping.sqs]
}

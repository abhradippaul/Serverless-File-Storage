locals {
  source_dir = abspath(var.source_path)

  # Collect all Backend source and configuration files to track changes
  backend_files = sort(setunion(
    fileset(local.source_dir, "src/**"),
    fileset(local.source_dir, "package.json"),
    fileset(local.source_dir, "pnpm-lock.yaml"),
    fileset(local.source_dir, "pnpm-workspace.yaml"),
    fileset(local.source_dir, "tsconfig.json")
  ))

  # Generate deterministic SHA256 hash of backend source files and configuration
  backend_hash = sha256(join("", [
    for f in local.backend_files : filesha256("${local.source_dir}/${f}")
  ]))
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
  name               = "${var.function_name}_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [var.s3_bucket_arn]
  }
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "${var.function_name}_s3_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_s3.json
}

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:Query",
      "dynamodb:GetItem"
    ]

    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.function_name}_dynamodb_policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Build the Backend TypeScript application to dist/index.mjs bundle
resource "terraform_data" "build_backend" {
  triggers_replace = [
    local.backend_hash
  ]

  provisioner "local-exec" {
    working_dir = local.source_dir
    command     = <<EOT
      set -e
      echo "==> Building Backend Lambda bundle..."
      if command -v pnpm >/dev/null 2>&1; then
        pnpm install
        pnpm run build
      else
        npm install
        npm run build
      fi
    EOT
  }
}

# Package the Lambda function code into a zip archive
data "archive_file" "this" {
  type        = "zip"
  source_file = "${local.source_dir}/dist/index.mjs"
  output_path = "${local.source_dir}/function.zip"

  depends_on = [terraform_data.build_backend]
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

  ephemeral_storage {
    size = var.ephemeral_storage
  }

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_s3,
    terraform_data.build_backend
  ]

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

# Lambda Function URL for HTTP endpoint
resource "aws_lambda_function_url" "this" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 3000
  }
}

resource "aws_lambda_permission" "function_url" {
  count                  = var.enable_function_url ? 1 : 0
  statement_id           = "AllowFunctionURLPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

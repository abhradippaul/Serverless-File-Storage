module "s3_bucket_for_file_storage" {
  source                 = "./modules/file_storage_s3_bucket"
  bucket_name            = var.file_storage_bucket_name
  creation_sqs_queue_arn = module.sqs_creation.sqs_queue_arn
  deletion_sqs_queue_arn = module.sqs_deletion.sqs_queue_arn
  tags                   = var.tags

  depends_on = [
    module.sqs_creation,
    module.sqs_deletion
  ]
}

module "s3_bucket_for_frontend_storage" {
  source      = "./modules/frontend_s3_bucket"
  bucket_name = var.frontend_bucket_name
  aws_profile = var.aws_profile
  api_url     = module.apigateway.api_endpoint
  tags        = var.tags
}

module "lambda_backend" {
  source = "./modules/lambda_backend"

  function_name       = var.file_storage_backend_lambda_name
  source_path         = var.backend_source_path
  handler             = var.backend_lambda_handler
  runtime             = var.backend_lambda_runtime
  architecture        = var.backend_lambda_architecture
  memory_size         = var.backend_lambda_memory_size
  timeout             = var.backend_lambda_timeout
  enable_function_url = var.enable_function_url
  s3_bucket_arn       = module.s3_bucket_for_file_storage.s3_bucket_arn
  dynamodb_table_arn  = module.dynamodb_metadata.table_arn

  environment_variables = {
    NODE_ENV                 = "production"
    FILE_STORAGE_BUCKET_NAME = var.file_storage_bucket_name
    DYNAMODB_TABLE_NAME      = module.dynamodb_metadata.table_name
  }

  tags = var.tags
}

module "apigateway" {
  source = "./modules/apigateway"

  api_name             = var.api_gateway_name
  lambda_invoke_arn    = module.lambda_backend.lambda_invoke_arn
  lambda_function_name = module.lambda_backend.lambda_function_name

  tags = var.tags
}

module "sqs_creation" {
  source = "./modules/sqs"

  name                       = var.creation_sqs_queue_name
  delay_seconds              = var.sqs_delay_seconds
  max_message_size           = var.sqs_max_message_size
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  source_arn                 = "arn:aws:s3:::${var.file_storage_bucket_name}"
  tags                       = var.tags
}

module "sqs_deletion" {
  source = "./modules/sqs"

  name                       = var.deletion_sqs_queue_name
  delay_seconds              = var.sqs_delay_seconds
  max_message_size           = var.sqs_max_message_size
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = var.sqs_receive_wait_time_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  source_arn                 = "arn:aws:s3:::${var.file_storage_bucket_name}"
  tags                       = var.tags
}

module "dynamodb_metadata" {
  source = "./modules/dynamodb"

  name      = var.metadata_dynamodb_table_name
  hash_key  = "user_id"
  range_key = "file_id"
  tags      = var.tags
}

module "lambda_metadata_processor_creation" {
  source = "./modules/lambda_metadata_processor"

  function_name      = var.metadata_processor_creation_lambda_name
  source_path        = var.metadata_processor_creation_source_path
  handler            = var.metadata_processor_lambda_handler
  runtime            = var.metadata_processor_lambda_runtime
  architecture       = var.metadata_processor_lambda_architecture
  memory_size        = var.metadata_processor_lambda_memory_size
  timeout            = var.metadata_processor_lambda_timeout
  s3_bucket_arn      = "arn:aws:s3:::${var.file_storage_bucket_name}"
  sqs_arn            = module.sqs_creation.sqs_queue_arn
  dynamodb_table_arn = module.dynamodb_metadata.table_arn

  environment_variables = {
    FILE_STORAGE_BUCKET_NAME = var.file_storage_bucket_name
    SQS_QUEUE_URL            = module.sqs_creation.sqs_queue_url
    DYNAMODB_TABLE_NAME      = module.dynamodb_metadata.table_name
  }

  tags = var.tags
}

module "lambda_metadata_processor_deletion" {
  source = "./modules/lambda_metadata_processor"

  function_name      = var.metadata_processor_deletion_lambda_name
  source_path        = var.metadata_processor_deletion_source_path
  handler            = var.metadata_processor_lambda_handler
  runtime            = var.metadata_processor_lambda_runtime
  architecture       = var.metadata_processor_lambda_architecture
  memory_size        = var.metadata_processor_lambda_memory_size
  timeout            = var.metadata_processor_lambda_timeout
  sqs_arn            = module.sqs_deletion.sqs_queue_arn
  dynamodb_table_arn = module.dynamodb_metadata.table_arn

  environment_variables = {
    FILE_STORAGE_BUCKET_NAME = var.file_storage_bucket_name
    SQS_QUEUE_URL            = module.sqs_deletion.sqs_queue_url
    DYNAMODB_TABLE_NAME      = module.dynamodb_metadata.table_name
  }

  tags = var.tags
}

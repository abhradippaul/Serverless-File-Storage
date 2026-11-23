module "s3_bucket_for_file_storage" {
  source      = "./modules/file_storage_s3_bucket"
  bucket_name = var.file_storage_bucket_name
  tags        = var.tags
}

module "s3_bucket_for_frontend_storage" {
  source      = "./modules/frontend_s3_bucket"
  bucket_name = var.frontend_bucket_name
  tags        = var.tags
}

# module "cloudfront" {
#   source = "./modules/cloudfront"

#   frontend_bucket_id                   = module.s3_bucket_for_frontend_storage.s3_bucket_name
#   frontend_bucket_arn                  = module.s3_bucket_for_frontend_storage.s3_bucket_arn
#   frontend_bucket_regional_domain_name = module.s3_bucket_for_frontend_storage.bucket_regional_domain_name
#   frontend_bucket_origin_id            = module.s3_bucket_for_frontend_storage.bucket_origin_id
#   tags                                 = var.tags
# }

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

  environment_variables = {
    NODE_ENV                 = "production"
    FILE_STORAGE_BUCKET_NAME = var.file_storage_bucket_name
  }

  tags = var.tags
}

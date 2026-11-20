resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# resource "aws_s3_bucket_notification" "bucket_notification" {
#   bucket = var.bucket_name

#   lambda_function {
#     lambda_function_arn = var.lambda_function_arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "audio-input/"
#     filter_suffix       = ".mp3"
#   }

#   depends_on = [aws_s3_bucket.this]
# }

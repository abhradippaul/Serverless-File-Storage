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

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name

  queue {
    queue_arn = var.creation_sqs_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }

  queue {
    queue_arn = var.deletion_sqs_queue_arn
    events    = ["s3:ObjectRemoved:*"]
  }

  depends_on = [aws_s3_bucket.this]
}

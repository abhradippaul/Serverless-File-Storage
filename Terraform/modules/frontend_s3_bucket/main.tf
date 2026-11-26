data "aws_region" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.tags
}

locals {
  frontend_dir = abspath(var.source_path != "" ? var.source_path : "${path.root}/../Frontend")

  # Collect all source and config files to track changes
  frontend_files = sort(setunion(
    fileset(local.frontend_dir, "src/**"),
    fileset(local.frontend_dir, "public/**"),
    fileset(local.frontend_dir, "*")
  ))

  # Generate deterministic SHA256 of frontend source code
  frontend_hash = sha256(join("", [
    for f in local.frontend_files : filesha256("${local.frontend_dir}/${f}")
  ]))
}

# Build and push Frontend dist to S3 using local-exec
resource "terraform_data" "frontend_package" {
  triggers_replace = [
    aws_s3_bucket.this.id,
    local.frontend_hash,
    var.api_url
  ]

  depends_on = [aws_s3_bucket.this]

  provisioner "local-exec" {
    working_dir = local.frontend_dir
    command     = <<EOT
      set -e
      PROFILE_FLAG="${var.aws_profile != "" ? "--profile ${var.aws_profile}" : ""}"
      REGION_FLAG="--region ${data.aws_region.current.region}"
      export VITE_API_URL="${var.api_url}"

      echo "==> Building Frontend application (VITE_API_URL=$VITE_API_URL)..."
      if command -v pnpm >/dev/null 2>&1; then
        pnpm install
        pnpm build
      else
        npm install
        npm run build
      fi

      echo "==> Syncing build output (dist/) to S3 bucket ${aws_s3_bucket.this.bucket}..."
      aws s3 sync dist/ "s3://${aws_s3_bucket.this.bucket}" --delete $PROFILE_FLAG $REGION_FLAG
    EOT
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "disaster_recovery" {
  bucket = "${var.project_name}-dr-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}_disaster_recovery"
    Environment = "shared"
    ManagedBy   = "terraform"
  }

}

resource "aws_s3_bucket_public_access_block" "disaster_recovery" {
  bucket = aws_s3_bucket.disaster_recovery.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "disaster_recovery" {
  bucket = aws_s3_bucket.disaster_recovery.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "disaster_recovery" {
  bucket = aws_s3_bucket.disaster_recovery.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

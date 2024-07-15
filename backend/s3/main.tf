terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.3.1"
}


/* KMS key to allow for the encryption of the state bucket */
resource "aws_kms_key" "terraform-bucket-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

/* KMS alias, which will be referred to later */
resource "aws_kms_alias" "key-alias" {
  name          = "alias/app-terraform-bucket-key"
  target_key_id = aws_kms_key.terraform-bucket-key.key_id
}

/* Create a secure S3 bucket */
resource "aws_s3_bucket" "terraform-state" {
  bucket        = "app-terraform-state-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform-state-versioning" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform-state-bucket-encryption" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "terraform-state-bucket-acl" {
  bucket = aws_s3_bucket.terraform-state.id
  acl    = "private"
}

/* Guarantees that the bucket is not publicly accessible */
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/* To prevent two team members from writing to the state file at the same time */
resource "aws_dynamodb_table" "terraform-lock" {
  name           = "app-terraform-state-table"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

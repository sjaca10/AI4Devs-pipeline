provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "${var.project_name}-code-bucket"
}

module "iam" {
  source = "./iam"
  project_name = var.project_name
  code_bucket  = aws_s3_bucket.code_bucket.bucket
}

module "backend" {
  source              = "./backend"
  project_name        = var.project_name
  code_bucket         = aws_s3_bucket.code_bucket.bucket
  iam_instance_profile = module.iam.ec2_instance_profile
}

module "frontend" {
  source              = "./frontend"
  project_name        = var.project_name
  code_bucket         = aws_s3_bucket.code_bucket.bucket
  iam_instance_profile = module.iam.ec2_instance_profile
}
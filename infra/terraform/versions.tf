terraform {
  # 1.10+ for S3 native state locking (use_lockfile) in the backend config.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # The EKS module 20.x line supports AWS provider >= 5.95, < 6.0.
      version = "~> 5.95"
    }
  }

  # Partial backend configuration: bucket, key and region are supplied per
  # environment at init time so the same code serves every environment:
  #
  #   terraform init \
  #     -backend-config="bucket=<state-bucket>" \
  #     -backend-config="key=eks/dev/terraform.tfstate" \
  #     -backend-config="region=us-east-1" \
  #     -backend-config="use_lockfile=true" \
  #     -backend-config="encrypt=true"
  backend "s3" {}
}

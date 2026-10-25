provider "aws" {
  region = var.region

  # Every taggable AWS resource gets the tagging convention, including ones
  # created inside community modules.
  default_tags {
    tags = local.tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"

  # Skip Local Zones / Wavelength Zones.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  # e.g. "eks-dev", "eks-prod". Argo CD registers the clusters under the same names.
  name = "${var.cluster_name_prefix}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Tagging convention applied to every resource (via provider default_tags)
  # and passed explicitly to modules so node group instances and volumes carry it too.
  tags = merge(var.extra_tags, {
    env         = var.environment
    team        = var.team
    cost-center = var.cost_center
    managed-by  = "terraform"
  })
}

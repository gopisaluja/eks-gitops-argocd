# IAM roles for service accounts (IRSA). Each role trusts exactly one
# namespace/service-account pair in this cluster's OIDC provider, so a pod
# only gets the AWS permissions of its own workload, not of the node.

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name             = "${local.name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name                     = "${local.name}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = var.route53_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }

  tags = local.tags
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name                     = "${local.name}-cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = var.route53_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  tags = local.tags
}

# Example application role: sample-api may only read its own SSM parameters.
data "aws_iam_policy_document" "sample_api" {
  statement {
    sid     = "ReadOwnParameters"
    actions = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/sample-api/*",
    ]
  }
}

resource "aws_iam_policy" "sample_api" {
  name        = "${local.name}-sample-api"
  description = "Read-only access to /${local.name}/sample-api/* SSM parameters"
  policy      = data.aws_iam_policy_document.sample_api.json
}

module "sample_api_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name = "${local.name}-sample-api"
  role_policy_arns = {
    ssm-read = aws_iam_policy.sample_api.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["sample-api:sample-api"]
    }
  }

  tags = local.tags
}

output "region" {
  description = "AWS region of the cluster."
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name (also the Argo CD destination name)."
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Kubernetes version of the control plane."
  value       = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 cluster CA, used when registering the cluster in Argo CD."
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN used by IRSA roles."
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (nodes and pods)."
  value       = module.vpc.private_subnets
}

output "irsa_role_arns" {
  description = "IRSA role ARNs to reference in Helm values (gitops/addons/values-<env>.yaml, charts/sample-api)."
  value = {
    ebs_csi      = module.ebs_csi_irsa.iam_role_arn
    external_dns = module.external_dns_irsa.iam_role_arn
    cert_manager = module.cert_manager_irsa.iam_role_arn
    sample_api   = module.sample_api_irsa.iam_role_arn
  }
}

output "configure_kubectl" {
  description = "Command to add this cluster to your kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}"
}

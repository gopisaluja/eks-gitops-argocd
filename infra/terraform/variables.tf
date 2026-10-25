variable "region" {
  description = "AWS region for the VPC and EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name. Used in resource names and the env tag."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "mgmt"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, mgmt."
  }
}

variable "team" {
  description = "Owning team, applied as the team tag."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for chargeback, applied as the cost-center tag."
  type        = string
}

variable "extra_tags" {
  description = "Additional tags merged into the standard set. Cannot override env, team, cost-center or managed-by."
  type        = map(string)
  default     = {}
}

variable "cluster_name_prefix" {
  description = "Cluster name prefix; the cluster is named <prefix>-<environment>."
  type        = string
  default     = "eks"
}

variable "cluster_version" {
  description = "Kubernetes minor version for the EKS control plane, e.g. \"1.35\". Check the EKS version calendar before changing."
  type        = string
  default     = "1.35"

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.cluster_version))
    error_message = "cluster_version must look like \"1.35\"."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR. Must be a /16; subnets are carved from it (see vpc.tf)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets and nodes across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, dev) instead of one per AZ (resilient, prod)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly (restricted by cluster_endpoint_public_access_cidrs)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Restrict to VPN/office egress ranges."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_role_arns" {
  description = "Map of name => IAM role ARN granted cluster admin through EKS access entries (e.g. SSO admin role, Argo CD hub role)."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch retention for control plane logs."
  type        = number
  default     = 30
}

variable "system_node_group" {
  description = "Sizing for the on-demand system node group."
  type = object({
    instance_types = optional(list(string), ["m6i.large"])
    min_size       = optional(number, 2)
    max_size       = optional(number, 4)
    desired_size   = optional(number, 2)
  })
  default = {}
}

variable "apps_node_group" {
  description = "Sizing and capacity type for the application node group."
  type = object({
    instance_types = optional(list(string), ["m6i.large", "m6a.large", "m5.large"])
    capacity_type  = optional(string, "SPOT")
    min_size       = optional(number, 1)
    max_size       = optional(number, 6)
    desired_size   = optional(number, 2)
  })
  default = {}

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.apps_node_group.capacity_type)
    error_message = "apps_node_group.capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "route53_zone_arns" {
  description = "Route 53 hosted zone ARNs that external-dns and cert-manager (DNS-01) may modify."
  type        = list(string)

  validation {
    condition     = length(var.route53_zone_arns) > 0
    error_message = "Provide at least one hosted zone ARN; avoid granting access to all zones."
  }
}

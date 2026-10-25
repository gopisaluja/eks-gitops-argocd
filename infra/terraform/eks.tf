module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Access entries only (no aws-auth ConfigMap). The identity running Terraform
  # gets cluster admin; additional admins (e.g. the Argo CD hub role, SSO admin
  # role) are granted through access entries below.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    for name, arn in var.cluster_admin_role_arns : name => {
      principal_arn = arn
      policy_associations = {
        cluster-admin = {
          policy_arn   = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # IRSA: creates the IAM OIDC provider for the cluster. EKS Pod Identity is
  # enabled as well via the eks-pod-identity-agent add-on below.
  enable_irsa = true

  cluster_enabled_log_types              = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  cluster_addons = {
    # Installed before the node groups so nodes join with networking ready.
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Prefix delegation raises pod density per node considerably.
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true
        }
      }
    }

    # Session Manager access instead of SSH keys.
    iam_role_additional_policies = {
      ssm = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    update_config = {
      max_unavailable_percentage = 33
    }
  }

  eks_managed_node_groups = {
    # Stable, on-demand capacity for controllers: Argo CD, ingress, cert-manager, monitoring.
    system = {
      instance_types = var.system_node_group.instance_types
      capacity_type  = "ON_DEMAND"
      min_size       = var.system_node_group.min_size
      max_size       = var.system_node_group.max_size
      desired_size   = var.system_node_group.desired_size

      labels = {
        "workload-class" = "system"
      }
    }

    # Application workloads. SPOT is a reasonable default for dev; prod uses ON_DEMAND.
    apps = {
      instance_types = var.apps_node_group.instance_types
      capacity_type  = var.apps_node_group.capacity_type
      min_size       = var.apps_node_group.min_size
      max_size       = var.apps_node_group.max_size
      desired_size   = var.apps_node_group.desired_size

      labels = {
        "workload-class" = "apps"
      }
    }
  }

  tags = local.tags
}

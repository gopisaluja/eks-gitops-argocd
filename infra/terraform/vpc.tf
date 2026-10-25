module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  # Address plan for a /16 (supports up to 4 AZs without overlap):
  #   private  /20 per AZ  -> x.x.0.0  - x.x.63.255   (nodes and pods)
  #   public   /24 per AZ  -> x.x.64.0 - x.x.67.255   (load balancers, NAT)
  #   intra    /24 per AZ  -> x.x.80.0 - x.x.83.255   (EKS control plane ENIs, no internet route)
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, 64 + i)]
  intra_subnets   = [for i, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, 80 + i)]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet discovery for Service type=LoadBalancer / AWS Load Balancer Controller.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

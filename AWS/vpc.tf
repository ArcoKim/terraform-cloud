locals {
    region = "ap-northeast-2"
    azs = ["a", "b", "c"]
    prefix = "skills"
    subnet_types = ["public", "private", "data"]

    vpc_cidr = "10.0.0.0/16"
    public_cidr = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
    private_cidr = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
    database_cidr = ["10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"]
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "${local.prefix}-vpc"
    cidr = local.vpc_cidr

    azs = [for az in local.azs: "${local.region}${az}"]

    public_subnets  = local.public_cidr
    public_subnet_names = [for az in local.azs: "${local.prefix}-${local.subnet_types[0]}-${az}"]
    map_public_ip_on_launch = true

    private_subnets = local.private_cidr
    private_subnet_names = [for az in local.azs: "${local.prefix}-${local.subnet_types[1]}-${az}"]

    database_subnets = local.database_cidr
    database_subnet_names = [for az in local.azs: "${local.prefix}-${local.subnet_types[2]}-${az}"]
    create_database_subnet_group = true
    create_database_subnet_route_table = true

    enable_nat_gateway = true
    single_nat_gateway = true
    one_nat_gateway_per_az = false

    enable_dns_hostnames = true
    enable_dns_support   = true

    enable_flow_log                      = true
    create_flow_log_cloudwatch_log_group = true
    create_flow_log_cloudwatch_iam_role  = true

    tags = {
        Terraform = "true"
    }
}
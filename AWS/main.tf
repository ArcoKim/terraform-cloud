module "vpc" {
  source = "./vpc"
}

module "bastion" {
  source   = "./bastion"
  vpc      = module.vpc.vpc
  public-a = module.vpc.public-a
}

module "eks" {
  source = "./eks"
  vpc = module.vpc.vpc
  public-a = module.vpc.public-a
  public-c = module.vpc.public-c
  private-a = module.vpc.private-a
  private-c = module.vpc.private-c
  bastion_role = module.bastion.bastion_role
}

module "ecs" {
  source = "./ecs"
  vpc = module.vpc.vpc
  private-a = module.vpc.private-a
  private-c = module.vpc.private-c
}

# module "seoul-2021" {
#   source = "./skills/2021-seoul"
# }

# module "national-2021" {
#   source = "./skills/2021-national"
# }

# module "national-2022" {
#   source = "./skills/2022-national"
# }
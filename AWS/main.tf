module "vpc" {
  source = "./vpc"
}

# module "bastion" {
#   source   = "./bastion"
#   vpc      = module.vpc.vpc
#   public-a = module.vpc.public-a
# }

# module "eks" {
#   source = "./eks"
#   vpc = module.vpc.vpc
#   public = module.vpc.public
#   private = module.vpc.private
#   bastion_role = module.bastion.bastion_role
# }

module "ecs" {
  source = "./ecs"
  vpc = module.vpc.vpc
  public = module.vpc.public
  private = module.vpc.private
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
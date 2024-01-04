# module "vpc" {
#   source = "./vpc"
# }

# module "bastion" {
#   source   = "./bastion"
#   vpc      = module.vpc.vpc
#   public-a = module.vpc.public-a
# }

module "seoul-2021" {
  source = "./skills/2021-seoul"
}
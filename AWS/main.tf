module "vpc" {
  source = "./vpc"
}

module "bastion" {
  source = "./bastion"
  vpc = module.vpc.vpc
  public-a = module.vpc.public-a
}
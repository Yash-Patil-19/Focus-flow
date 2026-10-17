module "network" {
  source             = "./modules/network"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source        = "./modules/security"
  project_name  = var.project_name
  vpc_id        = module.network.vpc_id
  container_port = var.container_port
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "alb" {
  source               = "./modules/alb"
  project_name         = var.project_name
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  container_port       = var.container_port
}

module "ecs" {
  source                      = "./modules/ecs"
  project_name                = var.project_name
  aws_region                  = var.aws_region
  private_subnet_ids          = module.network.private_subnet_ids
  ecs_security_group_id       = module.security.ecs_security_group_id
  target_group_arn            = module.alb.target_group_arn
  task_execution_role_arn     = module.iam.task_execution_role_arn
  image_uri                   = "${module.ecr.repository_url}:${var.image_tag}"
  container_port              = var.container_port
  desired_count               = var.desired_count
  task_cpu                    = var.task_cpu
  task_memory                 = var.task_memory
  depends_on                  = [module.alb]
}

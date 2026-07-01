
module "vpc" {
    source = "../../../modules/networking"
    environment = var.environment
    project_name = var.project_name
}
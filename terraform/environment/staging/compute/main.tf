module "ecr" {
  source = "../../../modules/ecr"

  repo_name = var.repo_name
}

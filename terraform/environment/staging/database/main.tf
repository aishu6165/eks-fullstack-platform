

module "dynamodb_table" {
  source = "../../../modules/dynamodb"

  dynamodb_table_name = var.dynamodb_table_name
}

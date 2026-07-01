module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    }
  ]
  # Global secondary index example (query by type)
  global_secondary_indexes = [
    {
        name            = "type-index"
        hash_key        = "sk"
        projection_type = "ALL"
    }
  ] 
  ttl_attribute_name = "expires_at"
  ttl_enabled        = true


  point_in_time_recovery_enabled = true

}
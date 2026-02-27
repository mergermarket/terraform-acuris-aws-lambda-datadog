provider "aws" {
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  max_retries                 = 1
  access_key                  = "a"
  secret_key                  = "a"
  region                      = "eu-west-1"
}

module "lambda" {
  source                         = "../.."
  image_uri                      = "image"
  image_config_command           = ["some_cmd"]
  image_config_entry_point       = ["some_entrypoint"]
  function_name                  = "check_lambda_function"
}

output "lambda_function_arn" {
  value = module.lambda.lambda_arn
}

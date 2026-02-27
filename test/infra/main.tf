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
  s3_bucket                      = "cdflow-lambda-releases"
  s3_key                         = "s3key.zip"
  function_name                  = "check_lambda_function"
  handler                        = "some_handler"
  runtime                        = "python3.7"
  lambda_env                     = var.lambda_env
  subnet_ids                     = var.subnet_ids
  security_group_ids             = var.security_group_ids
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tags                           = var.tags
  layers                         = var.layers
}

variable "subnet_ids" {
  type        = list(string)
  description = "The VPC subnets in which the Lambda runs."
  default     = []
}

variable "security_group_ids" {
  type        = list(string)
  description = "The VPC security groups assigned to the Lambda."
  default     = []
}

variable "lambda_env" {
  description = "Environment parameters passed to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for this Lambda"
  default     = -1
}

variable "tags" {
  description = "A mapping of tags to assign to this lambda function."
  type        = map(string)
  default     = {}
}

variable "layers" {
  type        = list(string)
  description = "ARNs of the layers to attach to the lambda function in order"
  default     = []
}

output "lambda_function_arn" {
  value = module.lambda.lambda_arn
}

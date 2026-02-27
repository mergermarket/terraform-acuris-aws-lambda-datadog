# AWS Lambda Terraform Module

[![Test](https://github.com/mergermarket/terraform-acuris-aws-lambda/actions/workflows/test.yml/badge.svg)](https://github.com/mergermarket/terraform-acuris-aws-lambda/actions/workflows/test.yml)

This module will deploy a Lambda function. It supports both Zip and Image deployments.

> NOTE 1: if image_uri is set then ECR Image will be deployed regardless of what Zip deployment properties are set to.

> NOTE 2: if both security_group_ids and subnet_ids are empty then the Lambda will not have access to resources within a VPC.

## Module input variables (shared)

- `function_name` - (string) - **REQUIRED** - The name of the Lambda function.
- `lambda_env` - (map) - Environment parameters passed to the Lambda function.
- `lambda_role_policy` (string) - The Lambda IAM Role Policy.
- `log_subscription_filter` - (string) - Subscription filter to filter logs sent to datadog.
- `memory_size` (number) - Amount of memory in MB your Lambda Function can use at runtime.
- `security_group_ids` - (list) - The VPC security groups assigned to the Lambda.
- `subnet_ids` - (list) - The VPC subnets in which the Lambda runs.
- `timeout` (number) - The maximum time in seconds that the Lambda can run for.
- `reserved_concurrent_executions` (number) - The amount of reserved concurrent executions for this lambda function.
- `tags` (map) - A mapping of tags to assign to this lambda function.
- `datadog_log_subscription_arn` - (string) - Log subscription arn for shipping logs to datadog.
- `architectures` - (list) - List of architectures to support for the Lambda function.
- `use_default_security_group` - (bool) - Use the default security group for the Lambda function.
- `vpc_id` - (string) - The VPC ID in which the Lambda runs.
- `tracing_mode` - (string) - Tracing mode for the Lambda. Valid options: PassThrough (default) and Active.
- `dead_letter_queue_arn` - (string)- The ARN of the dead letter queue for the Lambda function.

### Zip deployment variables
- `runtime` - (string) - **REQUIRED** - The runtime environment for the Lambda function you are uploading.
- `handler` - (map) - **REQUIRED** - The function within your code that Lambda calls to begin execution.
- `s3_bucket` - (string) - **REQUIRED** - The name of the bucket containing your uploaded Lambda deployment package.
- `s3_key` - (string) - **REQUIRED** - The s3 key for your Lambda deployment package.
- `layers` - (list) - ARNs of the layers to attach to the lambda function in order.

### Image deployment variables
- `image_uri` - (string) - **REQUIRED** - Uri to the image in ECR repo.
- `image_config_command` - (list) - List of values with which to override CMD entry in the image.
- `image_config_entry_point` - (list) - List of values with which to override ENTRYPOINT entry in the image.
- `image_config_working_directory` - (string) - Value with which to override WORKDIR entry in the image.


## Usage

```hcl
module "lambda" {
  source        = "mergermarket/aws-lambda/acuris"
  version       = "1.0.1"
  function_name = "do_foo"
  handler       = "do_foo_handler"
  runtime       = "nodejs"
  s3_bucket     = "s3_bucket_name"
  s3_key        = "s3_key_for_lambda"
  timeout       = 5
  memory_size   = 256
  lambda_env    = "${var.lambda_env}"
  architectures = ["x86_64"]
  use_default_security_group = true
  vpc_id = module.platform_config.config["vpc"]
}
```
Lambda environment variables file:
```json
{
  "lambda_env": {
    "environment_name": "ci-testing"
  }
}
```

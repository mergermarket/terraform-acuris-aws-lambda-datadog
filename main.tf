locals {
  security_group_ids = var.use_default_security_group == false ? var.security_group_ids : [data.aws_security_group.default[0].id]

  datadog_extension_layers_available = {
    x86_64 = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Extension:${var.datadog_extension_layer_version}"
    arm64  = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Extension-ARM:${var.datadog_extension_layer_version}"
  }
  datadog_lambdajs_layers_available = {
    "nodejs18.x" = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Node18-x:${var.datadog_lambdajs_layer_version}"
    "nodejs20.x" = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Node20-x:${var.datadog_lambdajs_layer_version}"
    "nodejs22.x" = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Node22-x:${var.datadog_lambdajs_layer_version}"
    "nodejs24.x" = "arn:aws:lambda:${data.aws_region.current.region}:464622532012:layer:Datadog-Node24-x:${var.datadog_lambdajs_layer_version}"
  }
  datadog_install_extension = var.datadog_metrics != "none"
  datadog_install_lambdajs  = var.datadog_metrics == "lambdajs"
  datadog_extension_layer   = local.datadog_install_extension ? [local.datadog_extension_layers_available[var.architectures[0]]] : []
  datadog_extension_env = local.datadog_install_extension ? {
    DD_SITE               = "datadoghq.com"
    DD_API_KEY_SECRET_ARN = data.aws_secretsmanager_secret.datadog_api_key.arn
  } : {}
  datadog_lambdajs_layer = local.datadog_install_lambdajs ? [local.datadog_lambdajs_layers_available[var.runtime]] : []
  datadog_lambdajs_env = local.datadog_install_lambdajs ? {
    DD_LAMBDA_HANDLER = var.handler
  } : {}
}

data "aws_region" "current" {
}

data "aws_security_group" "default" {
  count  = var.use_default_security_group == true ? 1 : 0
  name   = "${terraform.workspace}-default-lambda-sg"
  vpc_id = var.vpc_id
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  name = "${terraform.workspace == "live" ? "live" : "dev"}/datadog-agent-service"
}

resource "aws_lambda_function" "lambda_function" {
  image_uri                      = var.image_uri
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  function_name                  = var.function_name
  role                           = aws_iam_role.iam_for_lambda.arn
  handler                        = local.datadog_install_lambdajs ? "/opt/nodejs/node_modules/datadog-lambda-js/handler.handler" : var.handler
  runtime                        = var.runtime
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tags                           = var.tags
  package_type                   = var.image_uri != null ? "Image" : "Zip"
  layers                         = concat(var.layers, local.datadog_lambdajs_layer, local.datadog_extension_layer)
  architectures                  = var.architectures

  dynamic "image_config" {
    for_each = var.image_uri != null ? [1] : []
    content {
      command           = var.image_config_command
      entry_point       = var.image_config_entry_point
      working_directory = var.image_config_working_directory
    }
  }

  dynamic "vpc_config" {
    for_each = local.security_group_ids != null ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = local.security_group_ids
    }
  }

  environment {
    variables = merge(var.lambda_env, local.datadog_extension_env, local.datadog_lambdajs_env)
  }

  tracing_config {
    mode = var.tracing_mode
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_queue_arn != "" ? [1] : []  
    content {
      target_arn = var.dead_letter_queue_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_loggroup" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
  depends_on        = [aws_lambda_function.lambda_function]
}

resource "aws_cloudwatch_log_subscription_filter" "kinesis_log_stream" {
  count           = var.datadog_log_subscription_arn != "" ? 1 : 0
  name            = "kinesis-log-stream-${var.function_name}"
  destination_arn = var.datadog_log_subscription_arn
  log_group_name  = aws_cloudwatch_log_group.lambda_loggroup.name
  filter_pattern  = var.log_subscription_filter
  depends_on      = [aws_lambda_function.lambda_function]
}

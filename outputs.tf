output "lambda_arn" {
  value = module.lambda-datadog.arn
}

output "lambda_function_name" {
  value = module.lambda-datadog.function_name
}

output "lambda_iam_role_name" {
  value = aws_iam_role.iam_for_lambda.name
}

output "lambda_invoke_arn" {
  value = module.lambda-datadog.invoke_arn
}

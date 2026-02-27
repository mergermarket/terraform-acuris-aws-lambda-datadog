output "lambda_arn" {
  value = module.lambda-datadog.aws_lambda_function.this.arn
}

output "lambda_function_name" {
  value = module.lambda-datadog.aws_lambda_function.this.function_name
}

output "lambda_iam_role_name" {
  value = aws_iam_role.iam_for_lambda.name
}

output "lambda_invoke_arn" {
  value = module.lambda-datadog.aws_lambda_function.this.invoke_arn
}

resource "aws_iam_role" "iam_for_lambda" {
  name_prefix = replace(
    replace(var.function_name, "/(.{0,32}).*/", "$1"),
    "/^-+|-+$/",
    "",
  )
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.iam_for_lambda.id
  name = "policy"

  policy = var.lambda_role_policy
}

resource "aws_iam_role_policy_attachment" "vpc_permissions" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"

  count = length(var.subnet_ids) != 0 ? 1 : 0
}

resource "aws_iam_role_policy" "read_datadog_api_key" {
  count = local.datadog_install_extension ? 1 : 0
  role = aws_iam_role.iam_for_lambda.id
  name = "read_datadog_api_key"
  policy = data.aws_iam_policy_document.read_datadog_api_key.json
}

data "aws_iam_policy_document" "read_datadog_api_key" {
  statement {
    sid = "ReadSecrets"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      data.aws_secretsmanager_secret.datadog_api_key.arn,
    ]
  }
}
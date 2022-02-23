# === status ===

# --- IAM ---

resource "aws_iam_policy" "status_lambda" {
  description = "Lambda status Policy"
  name        = "stage-status-lambda"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy" "status_lambda_cloudwatch" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  tags  = var.default_tags
}

data "aws_iam_policy" "status_lambda_ec2" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  tags  = var.default_tags
}

data "aws_iam_policy" "status_lambda_vpc" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  tags  = var.default_tags
}

data "aws_iam_policy" "status_lambda_sqs" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  tags  = var.default_tags
}

resource "aws_iam_role" "status_lambda" {
  name  = "stage-status-lambda"
  tags  = var.default_tags
  assume_role_policy  = jsonencode({
    Version     = "2012-10-17"
    Statement  = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "status_lambda" {
  role        = "${aws_iam_role.status_lambda.name}"
  policy_arn  = "${aws_iam_policy.status_lambda.arn}"
}
  
resource "aws_iam_role_policy_attachment" "status_lambda_cloudwatch" {
  role        = "${aws_iam_role.status_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.status_lambda_cloudwatch.arn}"
}
  
resource "aws_iam_role_policy_attachment" "status_lambda_ec2" {
  role        = "${aws_iam_role.status_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.status_lambda_ec2.arn}"
}
  
resource "aws_iam_role_policy_attachment" "status_lambda_vpc" {
  role        = "${aws_iam_role.status_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.status_lambda_vpc.arn}"
}

resource "aws_iam_role_policy_attachment" "status_lambda_sqs" {
  role        = "${aws_iam_role.status_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.status_lambda_sqs.arn}"
}

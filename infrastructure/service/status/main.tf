# === status ===

# --- CloudWatch ---

resource "aws_cloudwatch_log_group" "stage_colorkeys_status" {
  name  = "${var.stage_status_log_group}"
  tags  = var.default_tags
}

# --- Lambda ---

resource "aws_iam_policy" "status_lambda" {
  description = "Lambda Policy"
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

data "archive_file" "stage_status_lambda" {
  type        = "zip"
  source_file = "${path.module}/${var.stage_status_lambda_source}"
  output_path = "${path.module}/${var.stage_status_lambda_zip}"
}

resource "aws_lambda_function" "status" {
  description       = "Load colorkeys histograms into database"
  filename          = "${path.module}/${var.stage_status_lambda_zip}"
  source_code_hash  = "${data.archive_file.stage_status_lambda.output_base64sha256}"
  function_name     = "${var.stage_status_lambda_funcname}"
  role              = "${aws_iam_role.status_lambda.arn}"
  handler           = "${var.stage_status_lambda_funcname}.lambda_handler"
  tags              = var.default_tags

  runtime = "python3.8"
  timeout = "300"

  environment {
    variables = {
      GITHUB_TOKEN   = "${var.GITHUB_TOKEN}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "status_lambda" {
  event_source_arn  = "${var.sqs_source}"
  function_name     = "${aws_lambda_function.status.arn}"
}

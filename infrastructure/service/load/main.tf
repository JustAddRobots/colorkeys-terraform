# === load ===

# --- CloudWatch ---

resource "aws_cloudwatch_log_group" "stage_colorkeys_load_dynamodb" {
  name  = "${var.stage_load_log_group}"
  tags  = var.default_tags
}

# --- DynamoDB ---

resource "aws_dynamodb_table" "stage_colorkeys" {
  name            = "stage-colorkeys"
  hash_key        = "filehash"
  range_key       = "selector"
  read_capacity   = 5
  write_capacity  = 5
  tags            = var.default_tags

  attribute {
    name  = "filehash"
    type  = "S"
  }

  attribute {
    name  = "selector"
    type  = "S"
  }
}

# --- Lambda ---

resource "aws_iam_policy" "load_lambda" {
  description = "Lambda load Policy"
  name        = "stage-load-lambda"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy" "load_lambda_cloudwatch" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  tags  = var.default_tags
}

data "aws_iam_policy" "load_lambda_ec2" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  tags  = var.default_tags
}

data "aws_iam_policy" "load_lambda_vpc" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  tags  = var.default_tags
}

resource "aws_iam_role" "load_lambda" {
  name  = "stage-load-lambda"
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

resource "aws_iam_role_policy_attachment" "load_lambda" {
  role        = "${aws_iam_role.load_lambda.name}"
  policy_arn  = "${aws_iam_policy.load_lambda.arn}"
}
  
resource "aws_iam_role_policy_attachment" "load_lambda_cloudwatch" {
  role        = "${aws_iam_role.load_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.load_lambda_cloudwatch.arn}"
}
  
resource "aws_iam_role_policy_attachment" "load_lambda_ec2" {
  role        = "${aws_iam_role.load_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.load_lambda_ec2.arn}"
}
  
resource "aws_iam_role_policy_attachment" "load_lambda_vpc" {
  role        = "${aws_iam_role.load_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.load_lambda_vpc.arn}"
}

data "archive_file" "stage_load_lambda" {
  type        = "zip"
  source_file = "${path.module}/${var.stage_load_lambda_source}"
  output_path = "${path.module}/${var.stage_load_lambda_zip}"
}

resource "aws_lambda_function" "load" {
  description       = "Load colorkeys histograms into database"
  filename          = "${path.module}/${var.stage_load_lambda_zip}"
  source_code_hash  = "${data.archive_file.stage_load_lambda.output_base64sha256}"
  function_name     = "${var.stage_load_lambda_funcname}"
  role              = "${aws_iam_role.load_lambda.arn}"
  handler           = "${var.stage_load_lambda_funcname}.lambda_handler"
  tags              = var.default_tags
  
  runtime = "python3.8"
  timeout = "300"
}

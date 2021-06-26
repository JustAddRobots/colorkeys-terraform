# === status ===

# --- CloudWatch ---

resource "aws_cloudwatch_log_group" "stage_colorkeys_status_github" {
  name  = "${var.stage_status_log_group_github}"
  tags  = var.default_tags
}


# --- Lambda ---

data "archive_file" "stage_status_lambda_github" {
  type        = "zip"
  source_file = "${path.module}/${var.stage_status_lambda_source_github}"
  output_path = "${path.module}/${var.stage_status_lambda_zip_github}"
}

resource "aws_lambda_function" "status_github" {
  description       = "Update GitHub API with CodePipeline status"
  filename          = "${path.module}/${var.stage_status_lambda_zip_github}"
  source_code_hash  = "${data.archive_file.stage_status_lambda_github.output_base64sha256}"
  function_name     = "${var.stage_status_lambda_funcname_github}"
  role              = "${aws_iam_role.status_lambda.arn}"
  handler           = "${var.stage_status_lambda_funcname_github}.lambda_handler"
  tags              = var.default_tags

  runtime = "python3.8"
  timeout = "300"
  layers  = ["${aws_lambda_layer_version.requests.arn}"]

  environment {
    variables = {
      GITHUB_TOKEN   = "${var.GITHUB_TOKEN}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "status_lambda_github" {
  event_source_arn  = "${var.sqs_source_github}"
  function_name     = "${aws_lambda_function.status_github.arn}"
}

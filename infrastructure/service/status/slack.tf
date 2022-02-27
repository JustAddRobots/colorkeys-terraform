# === status ===

# --- CloudWatch ---

resource "aws_cloudwatch_log_group" "stage_colorkeys_status_slack" {
  name  = "${var.stage_status_log_group_slack}"
  tags  = var.default_tags
}


# --- Lambda ---

data "archive_file" "stage_status_lambda_slack" {
  type        = "zip"
  source_file = "${path.module}/${var.stage_status_lambda_source_slack}"
  output_path = "${path.module}/${var.stage_status_lambda_zip_slack}"
}

resource "aws_lambda_function" "status_slack" {
  description       = "Update GitHub API with CodePipeline status"
  filename          = "${path.module}/${var.stage_status_lambda_zip_slack}"
  source_code_hash  = "${data.archive_file.stage_status_lambda_slack.output_base64sha256}"
  function_name     = "${var.stage_status_lambda_funcname_slack}"
  role              = "${aws_iam_role.status_lambda.arn}"
  handler           = "${var.stage_status_lambda_funcname_slack}.lambda_handler"
  tags              = var.default_tags

  runtime = "python3.8"
  timeout = "300"
  layers  = ["${aws_lambda_layer_version.requests.arn}"]

  environment {
    variables = {
      SLACK_URL_SUFFIX   = "${var.SLACK_URL_SUFFIX}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "status_lambda_slack" {
  event_source_arn  = "${var.sqs_source_slack}"
  function_name     = "${aws_lambda_function.status_slack.arn}"
}

# --- Lambda github ---

variable "sqs_source_github" {
  description = "SQS source for Lambda trigger, github"
  type        = string
}

variable "GITHUB_TOKEN" {
  description = "GitHub Personal Access Token"  # env var
  type        = string
  sensitive   = true
}

variable "stage_status_lambda_source_github" {
  description = "Lambda source, github status"
  type        = string
  default     = "stage-colorkeys-status-lambda-github.py"
}

variable "stage_status_lambda_zip_github" {
  description = "Lambda zip, github"
  type        = string
  default     = "stage-colorkeys-status-lambda-github.py.zip"
}

variable "stage_status_lambda_funcname_github" {
  description = "Lambda function name, github"
  type        = string
  default     = "stage-colorkeys-status-lambda-github"
}

variable "stage_status_log_group_github" {
  description = "CloudWatch log group for status, github"
  type        = string
  default     = "/aws/lambda/stage-colorkeys-status-lambda-github"
}

# --- Lambda slack ---

variable "sqs_source_slack" {
  description = "SQS source for Lambda trigger, slack"
  type        = string
}

variable "SLACK_URL_SUFFIX" {
  description = "Slack webhook"  # env var
  type        = string
  sensitive   = true
}

variable "stage_status_lambda_source_slack" {
  description = "Lambda source, slack status"
  type        = string
  default     = "stage-colorkeys-status-lambda-slack.py"
}

variable "stage_status_lambda_zip_slack" {
  description = "Lambda zip, slack"
  type        = string
  default     = "stage-colorkeys-status-lambda-slack.py.zip"
}

variable "stage_status_lambda_funcname_slack" {
  description = "Lambda function name, slack"
  type        = string
  default     = "stage-colorkeys-status-lambda-slack"
}

variable "stage_status_log_group_slack" {
  description = "CloudWatch log group for status, slack"
  type        = string
  default     = "/aws/lambda/stage-colorkeys-status-lambda-slack"
}

# --- Lambda layers ---

variable "stage_status_layer_requests" {
  description = "Lambda Layer, requests"
  type        = string
  default     = "~/tmp/stage-colorkeys-layer-requests.zip"
}

variable "stage_status_layer_requests_name" {
  description = "Lambda Layer name, requests"
  type        = string
  default     = "stage-colorkeys-status-layer-requests"
}

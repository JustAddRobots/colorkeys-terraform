variable "sqs_source" {
  description = "SQS source for Lambda trigger"
  type        = string
}

variable "GITHUB_TOKEN" {
  description = "GitHub Personal Access Token"  # env var
  type        = string
  sensitive   = true
}

variable "stage_status_lambda_source" {
  description = "Lambda source"
  type        = string
  default     = "stage-colorkeys-status-lambda.py"
}

variable "stage_status_lambda_zip" {
  description = "Lambda zip"
  type        = string
  default     = "stage-colorkeys-status-lambda.py.zip"
}

variable "stage_status_lambda_funcname" {
  description = "Lambda function name"
  type        = string
  default     = "stage-colorkeys-status-lambda"
}

variable "stage_status_log_group" {
  description = "CloudWatch log group for DynamoDB"
  type        = string
  default     = "/aws/lambda/stage-colorkeys-status-lambda"
}

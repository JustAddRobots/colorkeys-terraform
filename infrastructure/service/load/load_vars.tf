variable "stage_load_lambda_source" {
  description = "Lambda source"
  type        = string
  default     = "stage-colorkeys-load-lambda.py"
}

variable "stage_load_lambda_zip" {
  description = "Lambda zip"
  type        = string
  default     = "stage-colorkeys-load-lambda.py.zip"
}

variable "stage_load_lambda_funcname" {
  description = "Lambda function name"
  type        = string
  default     = "stage-colorkeys-load-lambda"
}

variable "stage_load_log_group" {
  description = "CloudWatch log group for DynamoDB"
  type        = string
  default     = "/aws/lambda/stage-colorkeys-load-lambda"
}

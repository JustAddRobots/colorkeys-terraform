variable "image" {
  description = "ECR repo build image"
  type        = string
}

variable "samples" {
  description = "S3 URI for image samples"
  type        = string
}

variable "stage_run_lambda_source" {
  description = "Lambda source"
  type        = string
  default     = "stage-colorkeys-run-lambda.py"
}

variable "stage_run_lambda_zip" {
  description = "Lambda zip"
  type        = string
  default     = "stage-colorkeys-run-lambda.py.zip"
}

variable "stage_run_lambda_funcname" {
  description = "Lambda function name"
  type        = string
  default     = "stage-colorkeys-run-lambda"
}

variable "stage_run_log_group" {
  description = "CloudWatch log group for ECS"
  type        = string
  default     = "/ecs/stage-colorkeys-run-ecs"
}

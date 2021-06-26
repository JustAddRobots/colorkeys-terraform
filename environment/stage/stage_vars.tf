# --- stage_vars ---

variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "stage"
}

# Terraform currently doesn't support vars in backed configuration.
# Below vars are unused.

variable "terraform_state" {
  description = "S3 bucket for Terraform state"
  default     = "stage-terraform-state-colorkeys"
}

variable "terraform_state_locks" {
  description = "DynamoDB for Terraform locks"
  default     = "stage-terraform-state-locks-colorkeys"
}

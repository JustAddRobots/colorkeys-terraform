# --- build_vars ---

variable "projectname" {
  description = "Name of build project"
  type        = string
}

variable "ecr_repo" {
  description = "ECR repo for build artifact"
  type        = string
}

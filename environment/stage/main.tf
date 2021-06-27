# === stage ===

data "aws_caller_identity" "current" {}

locals {
  aws_account_id                      = data.aws_caller_identity.current.account_id
  codepipeline_source_connection_arn  = "arn:aws:codestar-connections:${var.aws_region}:${local.aws_account_id}:connection/b3ad9daf-7ed4-4492-8488-aeeecfe69f97"
}

variable "GITHUB_TOKEN" {}  # env var
variable "SLACK_URL_SUFFIX" {}  # env var

module "pipeline" {
  aws_account_id    = "${local.aws_account_id}"
  source            = "../../infrastructure/service/pipeline"
  github_connection = "${local.codepipeline_source_connection_arn}" 
  GITHUB_TOKEN      = "${var.GITHUB_TOKEN}"
  SLACK_URL_SUFFIX  = "${var.SLACK_URL_SUFFIX}"
}

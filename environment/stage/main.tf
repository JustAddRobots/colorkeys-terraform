# === stage ===

variable "GITHUB_TOKEN" {}  # env var
variable "SLACK_URL_SUFFIX" {}  # env var

module "pipeline" {
  source            = "../../infrastructure/service/pipeline"
  GITHUB_TOKEN      = "${var.GITHUB_TOKEN}"
  SLACK_URL_SUFFIX  = "${var.SLACK_URL_SUFFIX}"
}

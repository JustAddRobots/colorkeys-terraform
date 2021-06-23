# === stage ===

variable "GITHUB_TOKEN" {}  # env var

module "pipeline" {
  source  = "../../infrastructure/service/pipeline"
  GITHUB_TOKEN = "${var.GITHUB_TOKEN}"
}

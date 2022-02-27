# === repository ===

resource "aws_ecr_repository" "stage_colorkeys_build_repo" {
  name  = "${var.codepipeline_build_repo}"
  tags  = var.default_tags
}

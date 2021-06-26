# === IAM ===

resource "aws_iam_policy" "codepipeline_service" {
  name        = "codepipeline-service"
  description = "CodePipeline Service Policy"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.codepipeline_service.json
}

resource "aws_iam_role" "codepipeline_service" {
  name                = "codepipeline-service"
  tags                = var.default_tags
  assume_role_policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_service" {
  role        = "${aws_iam_role.codepipeline_service.name}"
  policy_arn  = "${aws_iam_policy.codepipeline_service.arn}"
}

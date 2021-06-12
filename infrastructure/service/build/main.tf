# === build ===

data "aws_caller_identity" "current" {}

locals {
  aws_account_id  = data.aws_caller_identity.current.account_id
}

# --- CodeBuild ---

resource "aws_iam_policy" "codebuild_service" {
  name        = "codebuild-service"
  description = "CodeBuild Service Role"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.codebuild_service.json
}

resource "aws_iam_policy" "ecr_push" {
  name        = "ecr-push"
  description = "Push to ECR"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_policy" "codestar_github" {
  name        = "codestar-github"
  description = "Connect to github"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.codestar_github.json
}

resource "aws_iam_role" "codebuild_service" {
  name                = "codebuild-service"
  assume_role_policy  = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_service" {
  role        = "${aws_iam_role.codebuild_service.name}"
  policy_arn  = "${aws_iam_policy.codebuild_service.arn}"
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role        = "${aws_iam_role.codebuild_service.name}"
  policy_arn  = "${aws_iam_policy.ecr_push.arn}"
}

resource "aws_iam_role_policy_attachment" "codestar_github" {
  role        = "${aws_iam_role.codebuild_service.name}"
  policy_arn  = "${aws_iam_policy.codestar_github.arn}"
}

resource "aws_codebuild_project" "stage-colorkeys-build" {
  name          = "${var.projectname}"
  description   = "Colorkeys Docker build"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild_service.arn}"
  tags          = var.default_tags

  artifacts {
    type                = "CODEPIPELINE"
    name                = "build_artifact"
    packaging           = "NONE"
    encryption_disabled = false
  }

  cache {
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${var.aws_region}"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "ECR_REPO"
      value = "${var.ecr_repo}"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "ENGCOMMON_BRANCH"
      value = "main"
      type  = "PLAINTEXT"
    }

  }

  logs_config {
    cloudwatch_logs {
      status  = "ENABLED"
    }
    s3_logs {
      status              = "DISABLED"
      encryption_disabled = false
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 0
    insecure_ssl    = false
  }

  concurrent_build_limit  = 1
}

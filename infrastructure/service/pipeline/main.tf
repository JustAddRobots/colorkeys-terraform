# === pipeline ===

data "aws_caller_identity" "current" {}

locals {
  aws_account_id                      = data.aws_caller_identity.current.account_id
  codepipeline_source_connection_arn  = "arn:aws:codestar-connections:${var.aws_region}:${local.aws_account_id}:connection/fdf2d69f-c7cc-4d2c-93f4-0915b85d9c30"
}


# --- S3 ---

resource "aws_s3_bucket" "this" {
  bucket        = "${var.codepipeline_artifact_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket" "tmp_colorkeys" {
  bucket        = "${var.codepipeline_tmp_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket" "stage_colorkeys_samples" {
  bucket        = "${var.codepipeline_samples_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_s3_bucket_object" "samples" {
  bucket  = "${aws_s3_bucket.stage_colorkeys_samples.id}"
  key     = "${var.codepipeline_samples_key}"
  acl     = "private"
  source  = "${var.codepipeline_samples_source}"
  etag    = filemd5("${var.codepipeline_samples_source}")
}


# --- ECR ---

resource "aws_ecr_repository" "stage_colorkeys_build_repo" {
  name  = "${var.codepipeline_build_repo}"
  tags  = var.default_tags
}


# --- IAM ---

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
    Version     = "2012-10-17"
    Statement  = [
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


# --- modules ---

module "build" {
  source        = "../build"
  projectname   = "${var.codepipeline_build_projectname}"
  ecr_repo      = "${aws_ecr_repository.stage_colorkeys_build_repo.repository_url}"
}

module "run" {
  source    = "../run"
  image     = module.build.image
  samples   = "s3://${var.codepipeline_samples_bucket}/${var.codepipeline_samples_key}"
}

module "load" {
  source  = "../load"
}

# --- codepipeline ---

resource "aws_codepipeline" "stage_colorkeys" {
  name        = "stage-colorkeys"
  role_arn    = "${aws_iam_role.codepipeline_service.arn}"
  tags        = var.default_tags
  depends_on  = [
    aws_iam_role_policy_attachment.codepipeline_service,
  ]

  artifact_store {
    location  = "${var.codepipeline_artifact_bucket}"
    type      = "S3"
  }

  stage {
    name = "Source"

    action {
      name              = "source-colorkeys"
      category          = "Source"
      owner             = "AWS"
      provider          = "CodeStarSourceConnection"
      version           = "1"
      output_artifacts  = ["source_artifact"]
      namespace         = "codepipeline-source"

      configuration = {
        ConnectionArn         = "${local.codepipeline_source_connection_arn}"
        FullRepositoryId      = "${var.codepipeline_source_repo}"
        BranchName            = "${var.codepipeline_source_branch}"
        DetectChanges         = "false"
        OutputArtifactFormat  = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name              = "build-colorkeys"
      category          = "Build"
      owner             = "AWS"
      provider          = "CodeBuild"
      version           = "1"
      input_artifacts   = ["source_artifact"]
      output_artifacts  = ["build_artifact"]
      namespace         = "codepipeline-build"

      configuration     = {
        ProjectName     = "${module.build.projectname}"
      }
    }
  }

  stage {
    name = "Run"

    action {
      name              = "run-colorkeys"
      category          = "Invoke"
      owner             = "AWS"
      provider          = "Lambda"
      input_artifacts   = ["build_artifact"]
      output_artifacts  = ["run_output"]
      version           = "1"
      namespace         = "codepipeline-run"

      configuration     = {
        FunctionName    = "${var.codepipeline_run_funcname}"
      }
    }
  }

  stage {
    name = "Load"

    action {
      name              = "load-colorkeys"
      category          = "Invoke"
      owner             = "AWS"
      provider          = "Lambda"
      input_artifacts   = []
      output_artifacts  = ["load_output"]
      version           = "1"
      namespace         = "codepipeline-load"

      configuration = {
        FunctionName    = "${var.codepipeline_load_funcname}"
        UserParameters  = "#{codepipeline-run.task_arn}"
      }
    }
  }

}

# === pipeline ===

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

variable "GITHUB_TOKEN" {}  # env var
variable "SLACK_URL_SUFFIX" {}  # env var

module "status" {
  source            = "../status"
  sqs_source_github = "${aws_sqs_queue.stage_colorkeys_pipeline_github.arn}"
  sqs_source_slack  = "${aws_sqs_queue.stage_colorkeys_pipeline_slack.arn}"
  GITHUB_TOKEN      = "${var.GITHUB_TOKEN}"
  SLACK_URL_SUFFIX  = "${var.SLACK_URL_SUFFIX}"
}

resource "time_sleep" "wait_8_s" {
  depends_on      = [
    aws_iam_role_policy_attachment.codepipeline_service
  ]
  create_duration = "8s"
}


# --- codepipeline ---

resource "aws_codepipeline" "stage_colorkeys" {
  name        = "stage-colorkeys"
  role_arn    = "${aws_iam_role.codepipeline_service.arn}"
  tags        = var.default_tags
  depends_on  = [
    time_sleep.wait_8_s
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
        ConnectionArn         = "${var.github_connection}"
        FullRepositoryId      = "${var.codepipeline_source_repo}"
        BranchName            = "${var.codepipeline_source_branch}"
        DetectChanges         = "true"
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
      output_artifacts  = ["run_artifact"]
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
      input_artifacts   = ["run_artifact"]
      output_artifacts  = ["load_artifact"]
      version           = "1"
      namespace         = "codepipeline-load"

      configuration = {
        FunctionName    = "${var.codepipeline_load_funcname}"
        UserParameters  = "#{codepipeline-run.task_arn}"
      }
    }
  }
}

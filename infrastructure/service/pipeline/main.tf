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

# --- Notifications ---

resource "aws_codestarnotifications_notification_rule" "stage_colorkeys_pipeline" {
  name            = "stage-colorkeys-pipeline"
  detail_type     = "FULL"
  resource        = "${aws_codepipeline.stage_colorkeys.arn}"
  event_type_ids  = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded"
  ]
  target  {
    address = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
  }
}

resource "aws_cloudwatch_event_rule" "stage_colorkeys_pipeline" {
  name            = "stage-colorkeys-pipeline"
  description     = "CodePipeline Status Event"
  event_bus_name  = "default"
  tags            = var.default_tags

  event_pattern = <<EOF
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Pipeline Execution State Change"
  ],
  "detail": {
    "state": [
      "FAILED",
      "CANCELED",
      "STARTED",
      "RESUMED",
      "STOPPED",
      "SUCCEEDED",
      "SUPERSEDED"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "stage_colorkeys_pipeline" {
  rule      = "${aws_cloudwatch_event_rule.stage_colorkeys_pipeline.name}"
  target_id = "SendToSNS"
  arn       = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
}

# --- SNS ---

resource "aws_sns_topic" "stage_colorkeys_pipeline" {
  name  = "stage-colorkeys-pipeline"
}

resource "aws_sns_topic_policy" "stage_colorkeys_pipeline" {
  arn     = aws_sns_topic.stage_colorkeys_pipeline.arn
  policy  = data.aws_iam_policy_document.sns_topic.json
}

data "aws_iam_policy_document" "sns_topic" {
  policy_id = "__default_policy_ID"

  statement {
    sid = "__default_statement_ID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    resources = [
      "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        "${local.aws_account_id}",
      ]
    }
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "codestar-notifications.amazonaws.com"
      ]
    }
    actions = [
      "SNS:Publish",
    ]
    resources = [
      "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
    ]
  }
}

# data "aws_iam_policy_document" "sns_topic" {
#   statement {
#     effect  = "Allow"
#     actions = [
#       "SNS:Publish"
#     ]
#     principals {
#       type          = "Service"
#       identifiers   = [
#         "events.amazonaws.com"
#       ]
#     }
#     resources = [
#       aws_sns_topic.stage_colorkeys_pipeline.arn,
#     ]
#   }
# }

# --- SQS ---

resource "aws_sqs_queue" "stage_colorkeys_pipeline_deadletter" {
  name  = "stage-colorkeys-pipeline-deadletter"
  tags  = var.default_tags
}

resource "aws_sqs_queue" "stage_colorkeys_pipeline" {
  name                        = "stage-colorkeys-pipeline"
  visibility_timeout_seconds  = 300
  tags                        = var.default_tags
  redrive_policy              = jsonencode({
    deadLetterTargetArn = "${aws_sqs_queue.stage_colorkeys_pipeline_deadletter.arn}"
    maxReceiveCount     = 4
  })
}

# data "aws_iam_policy_document" "sqs_send" {
#   policy_id = "SQSSendAccess"
#   statement {
#     effect    = "Allow"
#     actions   = [
#       "SQS:*"
#     ]
#     resources = [
#       "${aws_sqs_queue.stage_colorkeys_pipeline.arn}"
#     ]
#     principals {
#       identifiers = ["*"]
#       type        = "*"
#     }
#     condition {
#       test     = "ArnEquals"
#       values   = [
#         "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
#       ]
#       variable = "aws:SourceArn"
#     }
#   }
# }  
  
resource "aws_sqs_queue_policy" "stage_colorkeys_pipeline" {
  queue_url = aws_sqs_queue.stage_colorkeys_pipeline.id
#   policy  = data.aws_iam_policy_document.sqs_send.json
  policy    = <<SQSPOLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.stage_colorkeys_pipeline.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
        }
      }
    }
  ]
}
SQSPOLICY
}

resource "aws_sns_topic_subscription" "stage_colorkeys_pipeline" {
  topic_arn = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.stage_colorkeys_pipeline.arn}"
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

variable "GITHUB_TOKEN" {}  # env var

module "status" {
  source      = "../status"
  sqs_source  = "${aws_sqs_queue.stage_colorkeys_pipeline.arn}"
  GITHUB_TOKEN = "${var.GITHUB_TOKEN}"
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

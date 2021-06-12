locals {
  codepipeline_source_connection_arn = "arn:aws:codestar-connections:${var.aws_region}:${local.aws_account_id}:connection/fdf2d69f-c7cc-4d2c-93f4-0915b85d9c30"
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.codepipeline_artifact_bucket}"
  acl           = "private"
  tags          = var.default_tags
  force_destroy = true
}

resource "aws_ecr_repository" "stage_colorkeys_build_repo" {
  name  = "${var.codepipeline_build_repo}"
  tags  = var.default_tags
}

resource "aws_iam_policy" "codepipeline_service" {
  name        = "codepipeline-service"
  description = "CodePipeline Service Policy"
  tags        = var.default_tags

  policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.codepipeline_artifact_bucket}",
        ]
      },
      {
        Effect = "Allow"
        Action = "logs:*"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action    = [
          "codecommit:CancelUploadArchive",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "codestar-connections:UseConnection"
        ]
        Resource  = "${local.codepipeline_source_connection_arn}"
        Effect    = "Allow"
      },
      {
        Action    = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "opsworks:CreateDeployment",
          "opsworks:DescribeApps",
          "opsworks:DescribeCommands",
          "opsworks:DescribeDeployments",
          "opsworks:DescribeInstances",
          "opsworks:DescribeStacks",
          "opsworks:UpdateApp",
          "opsworks:UpdateStack"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Action    = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ]
        Resource  = "*"
        Effect    = "Allow"
      },
      {
        Effect    = "Allow"
        Action    = [
          "devicefarm:ListProjects",
          "devicefarm:ListDevicePools",
          "devicefarm:GetRun",
          "devicefarm:GetUpload",
          "devicefarm:CreateUpload",
          "devicefarm:ScheduleRun"
        ]
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "servicecatalog:ListProvisioningArtifacts",
          "servicecatalog:CreateProvisioningArtifact",
          "servicecatalog:DescribeProvisioningArtifact",
          "servicecatalog:DeleteProvisioningArtifact",
          "servicecatalog:UpdateProduct"
        ]
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "cloudformation:ValidateTemplate"
        ]
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "ecr:DescribeImages"
        ]
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "states:DescribeExecution",
          "states:DescribeStateMachine",
          "states:StartExecution"
        ]
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = [
          "appconfig:StartDeployment",
          "appconfig:StopDeployment",
          "appconfig:GetDeployment"
        ]
        Resource  = "*"
      }
    ]
  })
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

resource "aws_codepipeline" "codepipeline" {
  name      = "stage-colorkeys"
  role_arn  = "${aws_iam_role.codepipeline_service.arn}"
  tags      = var.default_tags

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
        ProjectName     = "${var.codepipeline_build_projectname}"
      }
    }
  }

#   stage {
#     name = "Run"
# 
#     action {
#       name              = "run-colorkeys"
#       category          = "Invoke"
#       owner             = "AWS"
#       provider          = "Lambda"
#       input_artifacts   = ["build_artifact"]
#       output_artifacts  = ["run_output"]
#       version           = "1"
#       namespace         = "codepipeline-run"
# 
#       configuration     = {
#         FunctionName    = "${var.codepipeline_run_funcname}"
#       }
#     }
#   }
# 
#   stage {
#     name = "Load"
# 
#     action {
#       name              = "load-colorkeys"
#       category          = "Invoke"
#       owner             = "AWS"
#       provider          = "Lambda"
#       input_artifacts   = []
#       output_artifacts  = ["load_output"]
#       version           = "1"
#       namespace         = "codepipeline-load"
# 
#       configuration = {
#         FunctionName    = "${var.codepipeline_load_funcname}"
#         UserParamaters  = "#${codepipeline_run.task_arn}"
#       }
#     }
#   }

}

# === codepipeline_build ===

resource "aws_iam_policy" "codebuild_service" {
  name        = "codebuild-service"
  description = "CodeBuild Service Role"
  tags        = var.default_tags

  policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect    = "Allow"
        Resource  = "*"
      },
      {
        Action: [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Effect    = "Allow"
        Resource  = "*"
      },
      {
        Action: [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ],
        Effect: "Allow"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_push" {
  name        = "ecr-push"
  description = "Push to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "codestar_github" {
  name        = "codestar-github"
  description = "Connect to github"
  tags        = var.default_tags

  policy  = jsonencode({
    Version       = "2012-10-17"
    Statement     = [
      {
        Action    = [
          "codestar-connections:UseConnection"
        ]
        Effect    = "Allow"
        Resource  = "${local.codepipeline_source_connection_arn}"
      }
    ]
  })
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
  name          = "${var.codepipeline_build_projectname}"
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
      value = "${aws_ecr_repository.stage_colorkeys_build_repo.repository_url}"
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

# === codepipeline_run === 
# resource "aws_iam_policy" "this" {
#   name  = "stage-codepipeline-colorkeys-policy"
#   path  = "/"
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect  = "Allow",
#         Action  = [
#           "codepipeline:PutJobFailureResult",
#           "codepipeline:PutJobSuccessResult"
#         ],
#         Resource  = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:PutObject",
#           "s3:GetObject",
#           "s3:ListBucket",
#         ],
#         Resource = [
#           "arn:aws:s3:::${var.codepipeline_artifact_bucket}",
#         ]
#       },
#       {
#         Effect = "Allow",
#         Action = "logs:*",
#         Resource = "arn:aws:logs:*:*:*"
#       }
#     ]
#   })
# }

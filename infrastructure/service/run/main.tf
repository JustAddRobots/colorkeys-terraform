# === run ===

# --- CloudWatch ---

resource "aws_cloudwatch_log_group" "stage_colorkeys_run_ecs" {
  name  = "${var.stage_run_log_group}"
  tags  = var.default_tags
}

# --- ECS ---

data "aws_iam_policy" "ecs_task_exec" {
  arn   = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  tags  = var.default_tags
}

resource "aws_iam_policy" "ecs_task_exec_boto3" {
  description = "ECS Task Exec Policy for boto3"
  name        = "stage-ecs-task-exec_boto3"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.ecs_task_exec_boto3.json
}

resource "aws_iam_role" "ecs_task_exec" {
  name                = "stage-ecs-task_exec"
  tags                = var.default_tags
  assume_role_policy  = jsonencode({
    Version    = "2012-10-17"
    Statement  = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  role        = "${aws_iam_role.ecs_task_exec.name}"
  policy_arn  = "${data.aws_iam_policy.ecs_task_exec.arn}"
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_boto3" {
  role        = "${aws_iam_role.ecs_task_exec.name}"
  policy_arn  = "${aws_iam_policy.ecs_task_exec_boto3.arn}"
}

resource "aws_iam_policy" "ecs_task" {
  description = "ECS Task Policy"
  name        = "stage-ecs-task"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.ecs_task.json
}

resource "aws_iam_role" "ecs_task" {
  name                = "stage-ecs-task"
  tags                = var.default_tags
  assume_role_policy  = jsonencode({
    Version     = "2012-10-17"
    Statement   = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role        = "${aws_iam_role.ecs_task.name }"
  policy_arn  = "${aws_iam_policy.ecs_task.arn}"
}

resource "aws_ecs_task_definition" "stage_colorkeys-run" {
  family                    = "stage-colorkeys-run"
  execution_role_arn        = "${aws_iam_role.ecs_task_exec.arn}"
  task_role_arn             = "${aws_iam_role.ecs_task.arn}"
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = "512"
  memory                    = "1024"
  tags                      = var.default_tags

  container_definitions     = <<TASK_DEFINITION
[
    {
        "name": "${var.env}-colorkeys-run",
        "image": "${var.image}",
        "cpu": 512,
        "portMappings": [
            {
                "containerPort": 443,
                "hostPort": 443,
                "protocol": "tcp"
            }
        ],
        "essential": true,
        "environment": [
            {
                "name": "IMAGES",
                "value": "-i ${var.samples}"
            },
            {
                "name": "N_CLUSTERS",
                "value": "-n 7"
            },
            {
                "name": "COLORSPACES",
                "value": "-c HSV RGB"
            },
            {
                "name": "AWS",
                "value": "--aws"
            },
            {
                "name": "DEBUG",
                "value": "--debug"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group":  "${var.stage_run_log_group}",
                "awslogs-region": "us-west-1",
                "awslogs-stream-prefix": "ecs"
            }
        }
    }
]
TASK_DEFINITION

}

resource "aws_ecs_cluster" "workers" {
  name  = "workers"
  capacity_providers  = [
    "FARGATE",
    "FARGATE_SPOT"
  ]
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags  = var.default_tags
}
  
# --- Lambda ---

resource "aws_iam_policy" "run_lambda" {
  description = "Lambda run Policy"
  name        = "stage-run-lambda"
  tags        = var.default_tags
  policy      = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy" "run_lambda_cloudwatch" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  tags  = var.default_tags
}

data "aws_iam_policy" "run_lambda_ec2" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  tags  = var.default_tags
}

data "aws_iam_policy" "run_lambda_vpc" {
  arn   = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  tags  = var.default_tags
}

resource "aws_iam_role" "run_lambda" {
  name                = "stage-run-lambda"
  tags                = var.default_tags
  assume_role_policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "run_lambda" {
  role        = "${aws_iam_role.run_lambda.name}"
  policy_arn  = "${aws_iam_policy.run_lambda.arn}"
}
  
resource "aws_iam_role_policy_attachment" "run_lambda_cloudwatch" {
  role        = "${aws_iam_role.run_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.run_lambda_cloudwatch.arn}"
}
  
resource "aws_iam_role_policy_attachment" "run_lambda_ec2" {
  role        = "${aws_iam_role.run_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.run_lambda_ec2.arn}"
}
  
resource "aws_iam_role_policy_attachment" "run_lambda_vpc" {
  role        = "${aws_iam_role.run_lambda.name}"
  policy_arn  = "${data.aws_iam_policy.run_lambda_vpc.arn}"
}
  
data "archive_file" "stage_run_lambda" {
  type        = "zip"
  source_file = "${path.module}/${var.stage_run_lambda_source}"
  output_path = "${path.module}/${var.stage_run_lambda_zip}"
}

resource "aws_lambda_function" "run" {
  description       = "Run colorkeys against standardised images"
  filename          = "${path.module}/${var.stage_run_lambda_zip}"
  source_code_hash  = "${data.archive_file.stage_run_lambda.output_base64sha256}"
  function_name     = "${var.stage_run_lambda_funcname}"
  role              = "${aws_iam_role.run_lambda.arn}"
  handler           = "${var.stage_run_lambda_funcname}.lambda_handler"
  tags              = var.default_tags
  
  runtime = "python3.8"
  timeout = "300"
}

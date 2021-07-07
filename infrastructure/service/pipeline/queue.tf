# === queue ===

data "aws_iam_policy_document" "sqs_send" {
  policy_id = "SQSSendAccess"
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:SendMessage"
    ]
    resources = [
      "${aws_sqs_queue.stage_colorkeys_pipeline_github.arn}"
    ]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = [
        "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
      ]
      variable = "aws:SourceArn"
    }
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:SendMessage"
    ]
    resources = [
      "${aws_sqs_queue.stage_colorkeys_pipeline_slack.arn}"
    ]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = [
        "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
      ]
      variable = "aws:SourceArn"
    }
  }
}  

# --- SQS github ---

# SQS for github status updates
resource "aws_sqs_queue" "stage_colorkeys_pipeline_deadletter_github" {
  name                        = "stage-colorkeys-pipeline-deadletter-github"
#  name                        = "stage-colorkeys-pipeline-deadletter-github.fifo"
#  fifo_queue                  = true
#  content_based_deduplication = true
  tags                        = var.default_tags
}

resource "aws_sqs_queue" "stage_colorkeys_pipeline_github" {
  name                        = "stage-colorkeys-pipeline-github"
#  name                        = "stage-colorkeys-pipeline-github.fifo"
#  fifo_queue                  = true
#  content_based_deduplication = true
  visibility_timeout_seconds  = 300
  tags                        = var.default_tags
  redrive_policy              = jsonencode({
    deadLetterTargetArn = "${aws_sqs_queue.stage_colorkeys_pipeline_deadletter_github.arn}"
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue_policy" "stage_colorkeys_pipeline_github" {
  queue_url = aws_sqs_queue.stage_colorkeys_pipeline_github.id
  policy  = data.aws_iam_policy_document.sqs_send.json
}

resource "aws_sns_topic_subscription" "stage_colorkeys_pipeline_github" {
  topic_arn = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.stage_colorkeys_pipeline_github.arn}"
}

# --- SQS slack ---

# SQS for slack status updates
resource "aws_sqs_queue" "stage_colorkeys_pipeline_deadletter_slack" {
  name                        = "stage-colorkeys-pipeline-deadletter-slack"
#  name                        = "stage-colorkeys-pipeline-deadletter-slack.fifo"
#  fifo_queue                  = true
#  content_based_deduplication = true
  tags                        = var.default_tags
}

resource "aws_sqs_queue" "stage_colorkeys_pipeline_slack" {
  name                        = "stage-colorkeys-pipeline-slack"
#  name                        = "stage-colorkeys-pipeline-slack.fifo"
#  fifo_queue                  = true
#  content_based_deduplication = true
  visibility_timeout_seconds  = 300
  tags                        = var.default_tags
  redrive_policy              = jsonencode({
    deadLetterTargetArn = "${aws_sqs_queue.stage_colorkeys_pipeline_deadletter_slack.arn}"
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue_policy" "stage_colorkeys_pipeline_slack" {
  queue_url = aws_sqs_queue.stage_colorkeys_pipeline_slack.id
  policy  = data.aws_iam_policy_document.sqs_send.json
}

resource "aws_sns_topic_subscription" "stage_colorkeys_pipeline_slack" {
  topic_arn = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.stage_colorkeys_pipeline_slack.arn}"
}

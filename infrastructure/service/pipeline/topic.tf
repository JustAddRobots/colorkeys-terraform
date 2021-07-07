# === topic ===

resource "aws_sns_topic" "stage_colorkeys_pipeline" {
  name                        = "stage-colorkeys-pipeline"
#  name                        = "stage-colorkeys-pipeline.fifo"
#  fifo_topic                  = true
#  content_based_deduplication = true
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
        "${var.aws_account_id}",
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

# === notification ===

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

# resource "aws_cloudwatch_event_rule" "stage_colorkeys_pipeline" {
#   name            = "stage-colorkeys-pipeline"
#   description     = "CodePipeline Status Event"
#   event_bus_name  = "default"
#   tags            = var.default_tags
# 
#   event_pattern = <<EOF
# {
#   "source": [
#     "aws.codepipeline"
#   ],
#   "detail-type": [
#     "CodePipeline Pipeline Execution State Change"
#   ],
#   "detail": {
#     "state": [
#       "FAILED",
#       "CANCELED",
#       "STARTED",
#       "RESUMED",
#       "STOPPED",
#       "SUCCEEDED",
#       "SUPERSEDED"
#     ]
#   }
# }
# EOF
# }
# 
# resource "aws_cloudwatch_event_target" "stage_colorkeys_pipeline" {
#   rule      = "${aws_cloudwatch_event_rule.stage_colorkeys_pipeline.name}"
#   target_id = "SendToSNS"
#   arn       = "${aws_sns_topic.stage_colorkeys_pipeline.arn}"
#   sqs_target {
#     message_group_id = "stage-colorkeys"
#   }
# }

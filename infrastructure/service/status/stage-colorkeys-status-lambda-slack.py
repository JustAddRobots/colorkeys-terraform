"""
    This lambda parses CodePipeline notifications (via SQS) and posts to Slack API.
"""
import boto3
import json
import logging
import os
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def create_payload(notification):
    """Create HTTP request payload object for posting to the Slack API.

    Args:
        notification (dict): CodePipeline notification info.

    Returns:
        payload (dict): Request payload object.
    """
    pipeline_url = (
        f"https://{notification['region']}.console.aws.amazon.com/codesuite/"
        f"codepipeline/pipelines/{notification['pipeline']}/executions/"
        f"{notification['exec_id']}?region={notification['region']}"
    )

    # Image thumbnails for each CodePipeline state
    thumbnails = {
        "STARTED": (
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/"
            "White_on_White_%28Malevich%2C_1918%29.png/"
            "240px-White_on_White_%28Malevich%2C_1918%29.png"
        ),
        "RESUMED": (
            "https://upload.wikimedia.org/wikipedia/en/7/74/PicassoGuernica.jpg"
        ),
        "SUCCEEDED": (
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/"
            "Klimt_-_Orchard_with_Roses.jpg/240px-Klimt_-_Orchard_with_Roses.jpg"
        ),
        "FAILED": (
            "https://upload.wikimedia.org/wikipedia/en/c/cc/"
            "Atelier_rouge_matisse_1.jpg"
        ),
        "CANCELED": (
            "https://upload.wikimedia.org/wikipedia/en/c/cc/"
            "Atelier_rouge_matisse_1.jpg"
        ),
        "SUPERSEDED": (
            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/"
            "Nympheas_71293_3.jpg/320px-Nympheas_71293_3.jpg"
        ),
        "STOPPED": (
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/"
            "Vincent_Willem_van_Gogh_127.jpg/190px-Vincent_Willem_van_Gogh_127.jpg"
        ),
        "STOPPING": (
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/"
            "Vincent_Willem_van_Gogh_127.jpg/190px-Vincent_Willem_van_Gogh_127.jpg"
        )
    }

    message_text = (
        f"*{notification['state']}* {notification['pipeline']} "
        f"<{pipeline_url} | ({notification['exec_id'][:8]})> "
        f"{notification['timestamp']}\n"
        f"<{notification['commit_url']} | {notification['commit_id'][:8]}> "
        f"{notification['commit_msg']}"
    )

    # Add action and reason for failed state
    list_ = []
    failure_text = " "  # Slack fails on empty text string
    if notification["state"].lower() == "failed":
        for i in notification["failures"]:
            list_.append(f"{i['action']}: {i['additionalInformation']}")
        failure_text = "\n".join(list_)

    # Create payload, see Slack Block Kit Builder: https://api.slack.com/block-kit
    payload = {
        "text": message_text,
        "blocks": [
            {
                "type": "context",
                "elements": [
                    {
                        "type": "image",
                        "image_url": thumbnails[notification["state"]],
                        "alt_text": "thumbnail"
                    },
                    {
                        "type": "mrkdwn",
                        "text": message_text
                    }
                ]
            }
        ]
    }
    payload["blocks"][0]["elements"].append(
        {
            "type": "mrkdwn",
            "text": failure_text
        }
    )
    payload["blocks"].append(
        {
            "type": "divider",
        }
    )
    return payload


def post_status(url, payload):
    """Post status to Slack.

    Args:
        url (str): Slack API URL.
        payload (dict): HTTP request payload.

    Returns:
        res (str): HTTP response.
    """
    res = requests.post(url, json=payload)
    return res


def get_rev(pipeline, exec_id):
    """Get GitHub artifact revision from CopePipeline execution.

    Args:
        pipeline (str): Pipeline name.
        exec_id (str): Pipeline execution ID.

    Returns:
        rev (dict): Artifact revision for pipeline execution.
    """
    cp = boto3.client("codepipeline")
    r = cp.get_pipeline_execution(
        pipelineName = pipeline,
        pipelineExecutionId = exec_id
    )
    rev = next(i for i in r["pipelineExecution"]["artifactRevisions"])
    return rev


def get_notification(event):
    """Get notification info from SQS event.

    Args:
        event (SQS message event): CodePipeline notificataion piped through SNS.

    Returns:
        notification (dict): Summary of CodePipeline notification.
    """
    record = next(i for i in event["Records"])
    record_body = json.loads(record["body"])
    ev = json.loads(record_body["Message"])
    notification = {}
    notification["pipeline"] = ev["detail"]["pipeline"]
    notification["state"] = ev["detail"]["state"]
    notification["exec_id"] = ev["detail"]["execution-id"]
    notification["timestamp"] = record_body["Timestamp"]
    notification["region"] = record["awsRegion"]
    if notification["state"].lower() == "failed":
        notification["failures"] = ev["additionalAttributes"]["failedActions"]
    rev = get_rev(notification["pipeline"], notification["exec_id"])
    notification["commit_id"] = rev["revisionId"]
    notification["commit_url"] = rev["revisionUrl"]
    notification["commit_msg"] = json.loads(
        rev["revisionSummary"]
    )["CommitMessage"]
    logger.info(f"notification: {notification}")
    return notification


def post_sqs_status(event):
    """Parse SQS event and post status to Slack API.

    SQS event is subscribed to SNS topic.

    Args:
        event (SQS message event): CodePipeline notificataion piped through SNS.

    Returns:
        response (str): HTTP response.
    """
    notification = get_notification(event)
    payload = create_payload(notification)
    SLACK_URL_SUFFIX = os.getenv("SLACK_URL_SUFFIX")
    url = f"https://hooks.slack.com/services/{SLACK_URL_SUFFIX}"

    logger.info(f"payload: {payload}")
    logger.info(f"url: {url}")

    response = post_status(url, payload)
    return response


def lambda_handler(event, context):
    """Handle CodePipeline Notification in SQS event."""
    try:
        resp = post_sqs_status(event)
    except Exception as exc:
        logger.info("Lambda Failure")
        logger.info(f"event: {event}")
        logger.info(f"exc: {exc}")
    else:
        logger.info(f"resp: {resp}")
    logger.info("Lambda Complete")
    return None

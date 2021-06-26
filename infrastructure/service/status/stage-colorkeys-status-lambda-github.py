"""
    This lambda parses CodePipeline notifications (via SQS) and posts to Github API.
"""
import boto3
import json
import logging
import os
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_source_info(notification):
    """Get GitHub source code info.

    Args:
        notification (dict): CodePipeline notification info.

    Returns:
        source (dict): Source code information.
    """
    source = {}
    cp = boto3.client("codepipeline")
    dict_ = cp.get_pipeline_execution(
        pipelineName = notification["pipeline"],
        pipelineExecutionId = notification["exec_id"]
    )
    artifact = next(i for i in dict_["pipelineExecution"]["artifactRevisions"])
    source["commit"] = artifact["revisionId"]
    source["url"] = artifact["revisionUrl"]
    return source


def get_repo_info(pipeline_name):
    """Get GitHub repo info from CodePipeline configuration.

    Args:
        pipeline_name (str): pipeline name.

    Returns:
        repo (str): Github repo.
    """
    cp = boto3.client("codepipeline")
    dict_ = cp.get_pipeline(name=pipeline_name)
    source_stage = next(i for i in dict_["pipeline"]["stages"] if i["name"] == "Source")
    source_action = next(j for j in source_stage["actions"])
    repo = source_action["configuration"]["FullRepositoryId"]
    return repo


def create_payload(notification):
    """Create HTTP request payload object.

    Args:
        notification (dict): CodePipeline notification info.

    Returns:
        payload (dict): Request payload object.
    """
    if notification["state"].lower() in ["started", "resumed"]:
        state = "pending"
    elif notification["state"].lower() in ["failed", "canceled"]:
        state = "failure"
    elif notification["state"].lower() in ["succeeded"]:
        state = "success"

    target_url = (
        f"https://{notification['region']}.console.aws.amazon.com/codesuite/"
        f"codepipeline/pipelines/{notification['pipeline']}/executions/"
        f"{notification['exec_id']}?region={notification['region']}"
    )
    payload = {}
    payload["state"] = state
    payload["description"] = f"{notification['pipeline']} {notification['state']}"
    payload["context"] = "aws/codepipeline"
    payload["target_url"] = target_url
    return payload


def post_status(url, payload, token):
    """Post status to GitHub.

    Args:
        url (str): GitHub API URL.
        payload (dict): HTTP request payload.
        token (str): GitHub personal access token (from environment).

    Returns:
        res (str): HTTP response.
    """
    headers = {"Authorization": f"token {token}"}
    res = requests.post(url, json=payload, headers=headers)
    return res


def parse_sqs_status(event):
    """Parse SQS event.

    SQS event is subscribed to SNS topic.

    Args:
        event (SQS message event): CodePipeline notificataion piped through SNS.

    Returns:
        response (str): HTTP response.
    """
    # extract CodePipeline notification
    record = next(i for i in event["Records"])
    record_body = json.loads(record["body"])
    ev = json.loads(record_body["Message"])
    notification = {}
    notification["pipeline"] = ev["detail"]["pipeline"]
    notification["state"] = ev["detail"]["state"]
    notification["exec_id"] = ev["detail"]["execution-id"]
    notification["timestamp"] = record_body["Timestamp"]
    notification["region"] = record["awsRegion"]
    logger.info(f"notification: {notification}")

    # create payload and url for GitHub status update
    source = get_source_info(notification)
    repo = get_repo_info(notification["pipeline"])
    payload = create_payload(notification)
    url = f"https://api.github.com/repos/{repo}/statuses/{source['commit']}"
    token = os.getenv("GITHUB_TOKEN")

    logger.info(f"source: {source}")
    logger.info(f"payload: {payload}")
    logger.info(f"url: {url}")

    response = post_status(url, payload, token)
    return response


def lambda_handler(event, context):
    """Handle CodePipeline Notification in SQS event."""
    try:
        resp = parse_sqs_status(event)
    except Exception as exc:
        logger.info("Lambda Failure")
        logger.info(f"event: {event}")
        logger.info(f"exc: {exc}")
    else:
        logger.info(f"resp: {resp}")
    logger.info("Lambda Complete")
    return None

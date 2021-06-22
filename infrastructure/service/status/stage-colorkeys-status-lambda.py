import boto3
import json
import logging
import os
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_source_info(notification):
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
    cp = boto3.client("codepipeline")
    dict_ = cp.get_pipeline(name=pipeline_name)
    source_stage = next(i for i in dict_["pipeline"]["stages"] if i["name"] == "Source")
    source_action = next(j for j in source_stage["actions"])
    repo = source_action["configuration"]["FullRepositoryId"]
    return repo


def create_payload(notification):
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
    payload = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data = payload,
        headers = {"content-type": "application/json", "Authorization": "token {token}"}
    )
    res = urllib.request.urlopen(req)
    return res


def parse_sqs(event):
    record = next(i for i in event["Records"])
    record_body = json.loads(record["body"])
    ev = json.loads(record_body["Message"])
    notification = {}
    notification["pipeline"] = ev["detail"]["pipeline"]
    notification["state"] = ev["detail"]["state"]
    notification["exec_id"] = ev["detail"]["execution-id"]
    notification["exec_trigger"] = ev["detail"]["execution-trigger"]
    notification["timestamp"] = record_body["Timestamp"]
    notification["region"] = record["awsRegion"]

    source = get_source_info(notification)
    repo = get_repo_info(notification["pipeline"])
    payload = create_payload(notification)
    url = f"https://api.github.com/repos/{repo}/statuses/{source['commit']}"
    token = os.getenv("GITHUB_TOKEN")

    logger.info(f"notification: {notification}")
    logger.info(f"source: {source}")
    logger.info(f"payload: {payload}")
    logger.info(f"url: {url}")
    logger.info(f"token: {token}")

    response = post_status(url, payload, token)
    return response


def lambda_handler(event, context):
    """Handle Pipeline Notification.
    """
    try:
        r = parse_sqs(event)
    except Exception as e:
        logger.info("Lambda Failure")
        logger.info(f"event: {event}")
        logger.info(str(e))
    else:
        logger.info(r)
    logger.info("Lambda Complete")
    return None

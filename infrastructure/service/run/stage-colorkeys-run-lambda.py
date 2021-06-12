import boto3
import io
import logging
import json
import re
import zipfile

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_cluster_name(env):
    """Get cluster name using tags.

    This terraform module creates a cluster for the given environment.
    Get its name to use for running ECS tasks.

    Args:
        env (str): Environment name.

    Returns:
        cluster (str): Cluster name.
    """
    ecs = boto3.client("ecs")
    cluster = ""
    for c in ecs.list_clusters()["clusterArns"]:
        for t in ecs.list_tags_for_resource(resourceArn=c)["tags"]:
            if t["key"] == "environment" and t["value"] == env:
                regex = ".*cluster/([a-zA-Z0-9]+)"
                m = re.search(regex, c)
                if m:
                    cluster = m.groups()[0]
    logger.info(f"cluster: {cluster}")
    return cluster


def get_subnet_ids(env):
    """Get subnet IDs using tags.

    This terraform module creates a VPC and public subnet for ECS tasks.
    Get the subnet IDs for running ECS tasks.

    Args:
        env (str): Environment name.

    Returns:
        subnet_ids (list): Subnet IDs.
    """
    ec2 = boto3.resource("ec2")
    filters = [
        {"Name": "tag:environment", "Values": [env]},
        {"Name": "tag:type", "Values": ["public"]}
    ]
    subnet_ids = [i.id for i in list(ec2.subnets.filter(Filters=filters))]
    logger.info(f"subnet_ids: {subnet_ids}")
    return subnet_ids


def get_security_group_ids(env):
    """Get security group IDs using tags.

    This terraform module creates a VPC for ECS tasks.
    Get the security group IDs for running ECS tasks.

    Args:
        env (str): Environment name.

    Returns:
        sg_ids (list): Security group IDs.
    """
    ec2 = boto3.resource("ec2")
    filters = [{"Name": "tag:environment", "Values": [env]}]
    sg_ids = [i.id for i in list(ec2.security_groups.filter(Filters=filters))]
    logger.info(f"sg_ids: {sg_ids}")
    return sg_ids


def get_task_definition(env):
    """Get the task definition ARN.

    Args:
        env (str): Environment name.

    Returns:
        task_arn (str): Task definition ARN.
    """
    ecs = boto3.client("ecs")
    dict_ = ecs.list_task_definitions(
        familyPrefix = f"{env}-colorkeys-run",
        status = "ACTIVE",
        sort = "DESC",
        maxResults = 1
    )
    task_arn = next(i for i in dict_["taskDefinitionArns"])
    logger.info(f"task_arn: {task_arn}")
    return task_arn


def run_fargate_task():
    """Run the ECS task using Fargate.

    This terraform module defines a ECS task. Run this task using Fargate and
    previously created VPC bits.

    Args:
        None

    Returns:
        response (dict): ECS run_task response.
    """
    env = "stage"
    logger.info(f"env: {env}")
    ecs = boto3.client("ecs")
    response = ecs.run_task(
        cluster = get_cluster_name(env),
        count = 1,
        launchType = "FARGATE",
        networkConfiguration = {
            "awsvpcConfiguration": {
                "subnets": get_subnet_ids(env),
                "securityGroups": get_security_group_ids(env),
                "assignPublicIp": "ENABLED"
            }
        },
        taskDefinition = get_task_definition(env)
    )
    return response


def get_input_artifact(job, artifact_file, key):
    """Get input artifact.

    Get the input artifact from the CodePipeline S3 bucket. The S3 object contains
    an JSON artifact file which is loaded into an artifact object.

    Args:
        job (dict): CodePipeline job details.
        artifact_file (str): JSON artifact file.
        key (str): dict key used for artifact object inside artifact file.

    Returns:
        artifact (obj): input artifact.
    """
    logger.info(f"key: {key}")
    s3_input = next(i for i in job["data"]["inputArtifacts"])["location"]["s3Location"]
    bucket = s3_input["bucketName"]
    objkey = s3_input["objectKey"]
    s3 = boto3.resource("s3")
    logger.info(f"bucket: {bucket}")
    logger.info(f"objkey: {objkey}")
    s3obj = s3.Object(bucket, objkey)
    with zipfile.ZipFile(io.BytesIO(s3obj.get()["Body"].read())) as zf:
        with zf.open(artifact_file) as imgdef:
            obj = json.loads(imgdef.read().decode())
    artifact = next(i[key] for i in obj if i["name"] == "colorkeys")
    logger.info(f"artifact: {artifact}")
    return artifact


def lambda_handler(event, context):
    """Run CodePipeline stage."""
    job = event["CodePipeline.job"]
    cp = boto3.client("codepipeline")

    # Run Fargate ECS task, wait for completion.
    # Output task ARN to CodePipeline on success.

    # The colorkeys task uploads result to S3 tmp bucket with key in the format of
    # task_hash[:8].colorkeys.json.zip.
    try:
        logger.info(f"job: {job}")
        # img = get_input_artifact(job, "imagedefinitions.json", "imageUri")
        r = run_fargate_task()
        task_arn = r["tasks"][0]["taskArn"]
        ecs = boto3.client("ecs")
        waiter = ecs.get_waiter("tasks_stopped")
        logger.info(f"Waiting for {task_arn}")
        waiter.wait(cluster="workers", tasks=[task_arn])
    except Exception as e:
        logger.info("Lambda Failure")
        logger.info(str(e))
        cp.put_job_failure_result(
            jobId = job["id"],
            failureDetails = {"message": str(e), "type": "JobFailed"}
        )
    else:
        logger.info(r)
        cp.put_job_success_result(
            jobId = job["id"],
            outputVariables = {
                "task_arn": task_arn
            }
        )
    logger.info("Lambda Complete")
    return None

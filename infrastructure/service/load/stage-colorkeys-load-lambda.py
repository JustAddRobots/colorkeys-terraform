import boto3
import io
import logging
import json
import zipfile
from decimal import Decimal

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_task_arn(job):
    """Get UserParameters from CodePipeline job.

    Args:
        job (dict): CodePipeline Job details.

    Returns:
        task_arn (str): Task ARN.
    """
    task_arn = job["data"]["actionConfiguration"]["configuration"]["UserParameters"]
    logger.info(f"task_arn: {task_arn}")
    return task_arn


def get_obj_from_s3zip(bucket, objkey, internalfile):
    """Get object from S3 zip.

    Args:
        bucket (str): S3 Bucket name.
        objkey (str): S3 object key.
        internalfile (str): File inside S3 zip.

    Returns:
        obj (obj): Object loaded from internal JSON file.
    """
    s3 = boto3.resource("s3")
    logger.info(f"bucket: {bucket}")
    logger.info(f"objkey: {objkey}")
    s3obj = s3.Object(bucket, objkey)
    with zipfile.ZipFile(io.BytesIO(s3obj.get()["Body"].read())) as zf:
        with zf.open(internalfile) as obj_json:
            obj = json.loads(obj_json.read().decode(), parse_float=Decimal, parse_int=int)
    return obj


def get_task_obj(bucket, task_hash):
    """Get task object from S3.

    Args:
        bucket (str): S3 bucket.
        task_hash (str): Task hash.

    Returns:
        obj (object): Task result object.
    """
    internalfile = f"{task_hash[:8]}.colorkeys.json"
    objkey = f"{internalfile}.zip"
    obj = get_obj_from_s3zip(bucket, objkey, internalfile)
    logger.info(f"obj: {obj}")
    return obj


def load_colorkeys(table, colorkeys):
    """Load colorkeys object into DynamoDB table.

    Args:
        table (str): table name.
        colorkeys (list): colorkey objects

    Returns:
        response (dict): put_item response.
    """
    db = boto3.resource("dynamodb")
    tbl = db.Table(table)
    for colorkey in colorkeys:
        h = colorkey["histogram"]
        selector = (
            f'{h["algo"]}#{h["colorspace"]}#{h["n_clusters"]}#'
            f'{colorkey["cpu"]}#{colorkey["memory"]}#{colorkey["timestamp"]}'
        )
        logger.info(f"selector: {selector}")
        colorkey["selector"] = selector
        response = tbl.put_item(Item=colorkey)
    return response


def lambda_handler(event, context):
    """Run CodePipeline stage.

    Get task ARN from the codepipeline-run namespace UserParameters.
    Get colorkeys run results from S3 tmp bucket with key task_hash[:8].json.zip.
    Load results into DynamoDB table.
    """
    job = event["CodePipeline.job"]
    cp = boto3.client("codepipeline")
    logger.info(f"job: {job}")

    try:
        task_arn = get_task_arn(job)
        task_hash = task_arn.split("/")[-1]
        colorkeys = get_task_obj("tmp-colorkeys", task_hash)
        r = load_colorkeys("stage-colorkeys", colorkeys)
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
        )
    logger.info("Lambda Complete")
    return None

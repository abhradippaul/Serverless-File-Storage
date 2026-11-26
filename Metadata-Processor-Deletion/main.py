import json
import os
from urllib.parse import unquote_plus

import boto3
from boto3.dynamodb.conditions import Attr, Key

dynamodb = boto3.resource("dynamodb")


def extract_user_id(s3_key: str) -> str:
    """Extract user ID from S3 key (`uploads/<user_id>/...`)."""
    parts = s3_key.split("/", 2)
    if len(parts) >= 3 and parts[0] == "uploads" and parts[1]:
        return parts[1]

    return "anonymous"


def iter_s3_records(event: dict):
    """Yield S3 event records from either SQS-wrapped or direct S3 events."""
    for record in event.get("Records", []):
        if "s3" in record:
            yield record
            continue

        if "body" not in record:
            continue

        body = json.loads(record["body"])
        if body.get("Event") == "s3:TestEvent":
            continue

        for s3_record in body.get("Records", []):
            if "s3" in s3_record:
                yield s3_record


def handler(event, context):
    table_name = os.environ.get("DYNAMODB_TABLE_NAME", "drive-files-metadata")
    table = dynamodb.Table(table_name)

    deleted = 0
    for s3_record in iter_s3_records(event):
        s3_key = unquote_plus(s3_record["s3"]["object"]["key"])
        user_id = extract_user_id(s3_key)

        response = table.query(
            KeyConditionExpression=Key("user_id").eq(user_id),
            FilterExpression=Attr("s3_key").eq(s3_key),
        )

        for item in response.get("Items", []):
            key = {"user_id": item["user_id"]}
            if "file_id" in item:
                key["file_id"] = item["file_id"]
            table.delete_item(Key=key)
            deleted += 1

    return {"statusCode": 200, "deleted": deleted}

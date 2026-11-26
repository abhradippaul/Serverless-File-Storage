from datetime import datetime, timezone
import json
import os
from urllib.parse import unquote, unquote_plus
import uuid

import boto3

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")


def extract_user_id(s3_key: str, metadata: dict) -> str:
    """Extract user ID from S3 key (`uploads/<user_id>/...`) or object metadata."""
    parts = s3_key.split("/", 2)
    if len(parts) >= 3 and parts[0] == "uploads" and parts[1]:
        return parts[1]

    return metadata.get("user-id", "anonymous")


def get_object_details(bucket_name: str, s3_key: str) -> dict:
    """Fetch S3 object metadata and content type via HeadObject."""
    try:
        return s3.head_object(Bucket=bucket_name, Key=s3_key)
    except Exception:
        return {}


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

    processed = 0
    for s3_record in iter_s3_records(event):
        bucket_name = s3_record["s3"]["bucket"]["name"]
        obj = s3_record["s3"]["object"]
        s3_key = unquote_plus(obj["key"])

        head = get_object_details(bucket_name, s3_key)
        metadata = head.get("Metadata", {})

        user_id = extract_user_id(s3_key, metadata)
        raw_original_name = metadata.get("original-filename")
        file_name = (
            unquote(raw_original_name)
            if raw_original_name
            else s3_key.rsplit("/", 1)[-1]
        )
        file_size = int(obj["size"]) if "size" in obj else int(head.get("ContentLength", 0))
        content_type = head.get("ContentType", "application/octet-stream")
        now_iso = datetime.now(timezone.utc).isoformat()
        created_at = s3_record.get("eventTime") or now_iso

        item = {
            "user_id": user_id,
            "file_id": str(uuid.uuid4()),
            "file_name": file_name,
            "s3_key": s3_key,
            "file_size": file_size,
            "content_type": content_type,
            "created_at": created_at,
            "updated_at": now_iso,
        }

        table.put_item(Item=item)
        processed += 1

    return {"statusCode": 200, "processed": processed}

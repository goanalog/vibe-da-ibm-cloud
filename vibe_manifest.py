from base64 import b64decode
import json
from urllib.parse import urlparse
from sigv4 import put_object_sigv4

def main(params):
    required = ["COS_ACCESS_KEY_ID", "COS_SECRET_ACCESS_KEY", "REGION", "BUCKET", "body"]
    for r in required:
        if r not in params or not params[r]:
            return {"statusCode": 400, "body": f"Missing required param: {r}"}

    access = params["COS_ACCESS_KEY_ID"]
    secret = params["COS_SECRET_ACCESS_KEY"]
    region = params["REGION"]
    bucket = params["BUCKET"]
    key = params.get("key", "index.html")
    content_type = params.get("content_type", "text/html; charset=utf-8")

    body = params["body"]
    if isinstance(body, dict):
        body_bytes = json.dumps(body).encode("utf-8")
        content_type = "application/json"
    else:
        body_bytes = body.encode("utf-8")

    code, text = put_object_sigv4(
        access, secret, region, bucket, key, body_bytes, content_type=content_type, acl="public-read"
    )

    try:
        if "ANALYTICS_ENDPOINT" in params and params["ANALYTICS_ENDPOINT"]:
            import requests
            requests.post(params["ANALYTICS_ENDPOINT"], json={"event":"manifest"} , timeout=3)
    except Exception:
        pass

    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"ok": code in (200, 201), "status": code, "detail": text[:400]})
    }
import json
from sigv4 import put_object_sigv4

def main(params):
    event = params.get("event", "ping")
    region = params.get("REGION", "unknown")
    version = params.get("VERSION", "0.1.0")

    if not all(k in params for k in ["COS_ACCESS_KEY_ID","COS_SECRET_ACCESS_KEY","BUCKET"]):
        return {"statusCode": 200, "body": "analytics disabled (no creds)"}

    key = f"analytics/{__import__('datetime').datetime.utcnow().isoformat()}_{event}.json"
    body = json.dumps({"event": event, "region": region, "version": version}).encode("utf-8")

    code, _ = put_object_sigv4(
        params["COS_ACCESS_KEY_ID"],
        params["COS_SECRET_ACCESS_KEY"],
        region if region else "us-south",
        params["BUCKET"],
        key,
        body,
        content_type="application/json",
        acl="public-read"
    )
    return {"statusCode": 200, "body": json.dumps({"ok": True, "status": code})}
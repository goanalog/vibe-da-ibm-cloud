import json
from sigv4 import put_object_sigv4

def main(params):
    required = ["COS_ACCESS_KEY_ID", "COS_SECRET_ACCESS_KEY", "REGION", "BUCKET"]
    for r in required:
        if r not in params or not params[r]:
            return {"statusCode": 400, "body": f"Missing required param: {r}"}

    body = {
        "message": "Request to apply updated sample app configuration from within the Vibe IDE.",
        "project_id": params.get("PROJECT_ID", ""),
        "ts": __import__("datetime").datetime.utcnow().isoformat() + "Z"
    }
    body_bytes = json.dumps(body).encode("utf-8")

    code, text = put_object_sigv4(
        params["COS_ACCESS_KEY_ID"],
        params["COS_SECRET_ACCESS_KEY"],
        params["REGION"],
        params["BUCKET"],
        "project-update-request.json",
        body_bytes,
        content_type="application/json",
        acl="public-read"
    )

    try:
        if "ANALYTICS_ENDPOINT" in params and params["ANALYTICS_ENDPOINT"]:
            import requests
            requests.post(params["ANALYTICS_ENDPOINT"], json={"event":"update_project"} , timeout=3)
    except Exception:
        pass

    return {"statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"ok": True, "status": code})}
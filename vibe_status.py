import json, requests
def main(params):
    url = params.get("url")
    if not url:
        return {"statusCode": 400, "body": "Missing url"}
    try:
        r = requests.get(url, timeout=8)
        ok = r.status_code == 200
        return {"statusCode": 200 if ok else 502, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"ok": ok, "status": r.status_code})}
    except Exception as e:
        return {"statusCode": 502, "body": str(e)}
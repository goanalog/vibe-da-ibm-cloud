import base64, hashlib, hmac, json, os, datetime, urllib.request, urllib.error, urllib.parse

def _sign(key, msg): return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()
def _getSignatureKey(key, dateStamp, regionName, serviceName):
    kDate = _sign(("AWS4" + key).encode("utf-8"), dateStamp)
    kRegion = _sign(kDate, regionName)
    kService = _sign(kRegion, serviceName)
    kSigning = _sign(kService, "aws4_request")
    return kSigning

def _s3_request(method, host, region, bucket, key, body=b"", headers=None, extra_query=None):
    service = "s3"
    endpoint = f"https://{host}/{bucket}/{key}"
    t = datetime.datetime.utcnow()
    amzdate = t.strftime("%Y%m%dT%H%M%SZ")
    datestamp = t.strftime("%Y%m%d")
    access_key = os.environ.get("COS_ACCESS_KEY_ID")
    secret_key = os.environ.get("COS_SECRET_ACCESS_KEY")
    if not access_key or not secret_key:
        raise Exception("Missing COS HMAC credentials")
    payload_hash = hashlib.sha256(body).hexdigest()
    canonical_uri = f"/{bucket}/{key}"
    canonical_querystring = "" if not extra_query else urllib.parse.urlencode(extra_query)
    default_headers = {
        "host": host,
        "x-amz-content-sha256": payload_hash,
        "x-amz-date": amzdate,
    }
    if headers: default_headers.update(headers)
    signed_headers = ";".join(sorted([h.lower() for h in default_headers.keys()]))
    canonical_headers = "".join([f"{h.lower()}:{default_headers[h]}\n" for h in sorted(default_headers.keys())])
    canonical_request = "\n".join([method, canonical_uri, canonical_querystring, canonical_headers, signed_headers, payload_hash])
    algorithm = "AWS4-HMAC-SHA256"
    credential_scope = f"{datestamp}/{region}/{service}/aws4_request"
    string_to_sign = "\n".join([algorithm, amzdate, credential_scope, hashlib.sha256(canonical_request.encode("utf-8")).hexdigest()])
    signing_key = _getSignatureKey(secret_key, datestamp, region, service)
    signature = hmac.new(signing_key, string_to_sign.encode("utf-8"), hashlib.sha256).hexdigest()
    authorization_header = f"{algorithm} Credential={access_key}/{credential_scope}, SignedHeaders={signed_headers}, Signature={signature}"
    req = urllib.request.Request(endpoint + (("?" + canonical_querystring) if canonical_querystring else ""),
                                 data=(body if method in ("PUT","POST") else None), method=method)
    for k,v in default_headers.items(): req.add_header(k, v)
    req.add_header("Authorization", authorization_header)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return 599, str(e).encode()

def main(args):
    bucket = os.environ.get("BUCKET")
    region = os.environ.get("REGION", "us-south")
    host = f"s3.{region}.cloud-object-storage.appdomain.cloud"
    action = args.get("action","upload")
    project_mode = os.environ.get("PROJECT_MODE")
    if project_mode == "update_request":
        note = args.get("note","user requested update")
        key = "project-update-request.json"
        body = json.dumps({"note": note, "ts": datetime.datetime.utcnow().isoformat()+"Z"}).encode()
        status, data = _s3_request("PUT", host, region, bucket, key, body=body, headers={"Content-Type":"application/json"})
        return {"ok": 200 <= status < 300, "status": status, "body": data.decode(errors="ignore")}
    if action == "rollback":
        src = f"/{bucket}/index.prev.html"
        headers = {"x-amz-copy-source": src}
        status, data = _s3_request("PUT", host, region, bucket, "index.html", body=b"", headers=headers)
        if not (200 <= status < 300):
            return {"ok": False, "error": "No previous version or copy failed", "status": status}
        return {"ok": True, "status": status}
    key = args.get("key","index.html")
    content_b64 = args.get("content_b64","")
    try:
        content = base64.b64decode(content_b64.encode())
    except Exception:
        return {"ok": False, "error":"invalid base64 content"}
    _s3_request("PUT", host, region, bucket, "index.prev.html", body=b"", headers={"x-amz-copy-source": f"/{bucket}/{key}"})
    status, data = _s3_request("PUT", host, region, bucket, key, body=content, headers={"Content-Type":"text/html; charset=utf-8"})
    return {"ok": 200 <= status < 300, "status": status}

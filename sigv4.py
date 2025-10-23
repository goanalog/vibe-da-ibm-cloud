# Minimal AWS SigV4 for IBM COS HMAC (PUT Object)
import hashlib, hmac, datetime, urllib.parse

def _sign(key, msg):
    return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()

def _get_signature_key(key, dateStamp, regionName, serviceName="s3"):
    kDate = _sign(('AWS4' + key).encode('utf-8'), dateStamp)
    kRegion = hmac.new(kDate, regionName.encode('utf-8'), hashlib.sha256).digest()
    kService = hmac.new(kRegion, serviceName.encode('utf-8'), hashlib.sha256).digest()
    kSigning = hmac.new(kService, b'aws4_request', hashlib.sha256).digest()
    return kSigning

def put_object_sigv4(
    access_key_id, secret_access_key, region, bucket, key, body_bytes,
    content_type="text/html; charset=utf-8", acl="public-read"
):
    host = f"s3.{region}.cloud-object-storage.appdomain.cloud"
    endpoint = f"https://{host}/{bucket}/{urllib.parse.quote(key)}"

    method = "PUT"
    service = "s3"
    t = datetime.datetime.utcnow()
    amz_date = t.strftime('%Y%m%dT%H%M%SZ')
    date_stamp = t.strftime('%Y%m%d')

    payload_hash = hashlib.sha256(body_bytes).hexdigest()
    canonical_uri = f"/{bucket}/{key}"
    canonical_querystring = ""

    canonical_headers = (
        f"content-type:{content_type}\n"
        f"host:{host}\n"
        f"x-amz-acl:{acl}\n"
        f"x-amz-content-sha256:{payload_hash}\n"
        f"x-amz-date:{amz_date}\n"
    )
    signed_headers = "content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date"

    canonical_request = "\n".join([
        method, canonical_uri, canonical_querystring,
        canonical_headers, signed_headers, payload_hash
    ])

    algorithm = 'AWS4-HMAC-SHA256'
    credential_scope = f"{date_stamp}/{region}/{service}/aws4_request"
    string_to_sign = "\n".join([
        algorithm, amz_date, credential_scope,
        hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()
    ])
    signing_key = _get_signature_key(secret_access_key, date_stamp, region, service)
    signature = hmac.new(signing_key, string_to_sign.encode('utf-8'), hashlib.sha256).hexdigest()

    authorization_header = (
        f"{algorithm} Credential={access_key_id}/{credential_scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )

    import requests
    headers = {
        "Content-Type": content_type,
        "x-amz-acl": acl,
        "x-amz-content-sha256": payload_hash,
        "x-amz-date": amz_date,
        "Authorization": authorization_header,
    }
    resp = requests.put(endpoint, data=body_bytes, headers=headers, timeout=30)
    return resp.status_code, resp.text
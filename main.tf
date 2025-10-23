provider "ibm" { region = var.region }

data "ibm_resource_group" "rg" { name = var.resource_group_name }

resource "random_string" "suffix" { length=6 upper=false special=false }

resource "ibm_resource_instance" "cos" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.rg.id
}

resource "ibm_cos_bucket" "vibe" {
  bucket_name          = coalesce(var.bucket_name, "vibe-${random_string.suffix.result}")
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
  endpoint_type        = "public"
}

resource "ibm_resource_key" "cos_hmac" {
  name                 = "vibe-hmac-${random_string.suffix.result}"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id
  parameters = { HMAC = true }
}

locals {
  cos_access_key = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].access_key_id
  cos_secret_key = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].secret_access_key
  bucket         = ibm_cos_bucket.vibe.bucket_name
  region         = var.region
}

resource "local_file" "sigv4_py" { content = <<PY
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
PY
  filename = "${path.module}/sigv4.py"
}
resource "local_file" "vibe_manifest_py" { content = <<PY
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
PY
  filename = "${path.module}/vibe_manifest.py"
}
resource "local_file" "vibe_status_py" { content = <<PY
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
PY
  filename = "${path.module}/vibe_status.py"
}
resource "local_file" "vibe_update_project_py" { content = <<PY
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
PY
  filename = "${path.module}/vibe_update_project.py"
}
resource "local_file" "vibe_analytics_py" { content = <<PY
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
PY
  filename = "${path.module}/vibe_analytics.py"
}

resource "local_file" "vibe_index_py" {
  content  = <<PY
INDEX_HTML = r"""
<!DOCTYPE html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Vibe Landing Zone — Max Vibe Edition</title>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/monokai.min.css">
<style>
  :root { --fg:#e5e7eb; --bg:#000 }
  html,body{height:100%;margin:0} body{background:var(--bg);color:var(--fg);font-family:'IBM Plex Sans',system-ui;overflow:hidden}
  #editor{position:fixed;top:7vh;left:6vw;width:calc(100vw - 12vw);min-height:40vh;background:rgba(10,12,18,.78);border:1px solid rgba(147,197,253,.15);border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.45),0 0 40px rgba(15,98,254,.22) inset;z-index:4}
  #editor-title{display:flex;gap:.6rem;align-items:center;padding:.8rem 1rem;border-bottom:1px solid rgba(147,197,253,.15)}
  .dot{width:.7rem;height:.7rem;border-radius:50%}
  #actions{display:flex;justify-content:flex-end;gap:.5rem;padding:.8rem 1rem 1rem}
  .btn{border:none;border-radius:9999px;padding:.65rem 1.1rem;font-weight:800;background:linear-gradient(135deg,#3b82f6,#22d3ee);color:#fff;cursor:pointer}
  .secondary-btn{background:rgba(147,197,253,.08);color:#c7d2fe;border:1px solid rgba(147,197,253,.3);border-radius:9999px;padding:.5rem .9rem;font-weight:600;cursor:pointer}
  #banner{position:fixed;top:10px;left:50%;transform:translateX(-50%);background:rgba(17,24,39,.85);color:#e5e7eb;padding:.6rem 1rem;border-radius:12px;border:1px solid rgba(99,102,241,.4);display:none;z-index:10}
  #ai-credit{position:fixed;bottom:12px;right:14px;cursor:pointer;z-index:10}
  #ai-credit img{width:36px;height:36px;filter:drop-shadow(0 0 6px rgba(255,255,255,.4));transition:transform .25s ease}
  #ai-credit:hover img{transform:scale(1.08)}
  #ai-credit .tooltip{position:absolute;bottom:45px;right:0;background:rgba(0,0,0,.9);color:#fff;padding:8px 10px;border-radius:8px;font-size:.8rem;white-space:nowrap;opacity:0;pointer-events:none;transform:translateY(5px);transition:all .25s ease}
  #ai-credit:hover .tooltip,#ai-credit:focus-within .tooltip{opacity:1;transform:translateY(0)}
  .CodeMirror{height:36vh;border-top:1px solid rgba(147,197,253,.15)}
</style></head>
<body>
<div id="banner"></div>
<section id="editor" aria-label="Vibe code editor">
  <div id="editor-title">
    <span class="dot" style="background:#ff5f56"></span>
    <span class="dot" style="background:#ffbd2f"></span>
    <span class="dot" style="background:#27c93f"></span>
    <span class="ml-2" style="opacity:.8">/vibe-code.html</span>
  </div>
  <textarea id="code" spellcheck="false"></textarea>
  <div id="actions">
    <button id="copyCode" class="secondary-btn" type="button">Copy Code ❐</button>
    <button id="revert" class="secondary-btn" type="button">Revert ↩</button>
    <button id="updateProject" class="secondary-btn" type="button">Pro Update 🌈</button>
    <button id="manifest" class="btn" type="button">Manifest ✨</button>
  </div>
</section>
<div id="ai-credit" tabindex="0">
  <img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9ImciIHgxPSIwIiB5MT0iMCIgeDI9IjEiIHkyPSIxIj4KICAgIDxzdG9wIG9mZnNldD0iMCUiIHN0b3AtY29sb3I9IiM3QzNBRUQiLz48c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMwNkI2RDQiLz4KICA8L2xpbmVhckdyYWRpZW50PjwvZGVmcz4KICA8cmVjdCB4PSIyIiB5PSIyIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHJ4PSIxNCIgc3Ryb2tlPSJ1cmwoI2cpIiBzdHJva2Utd2lkdGg9IjIiIGZpbGw9ImJsYWNrIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MiUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZpbGw9IndoaXRlIiBmb250LWZhbWlseT0iSUJNIFBsZXggU2FucyIgZm9udC1zaXplPSIyMCIgZm9udC13ZWlnaHQ9IjcwMCI+QUk8L3RleHQ+Cjwvc3ZnPg==" alt="AI-assisted"/>
  <div class="tooltip">
    🤖 Made with AI assistance, inspired by Arn Hyndman’s
    <a href="https://cloud.ibm.com/catalog" target="_blank" style="color:#a5b4fc">Static Website Deployable Architecture</a>.
  </div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/xml/xml.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/javascript/javascript.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/css/css.min.js"></script>
<script>
const UPLOAD = "%%UPLOAD_ENDPOINT%%";
const STATUS = "%%STATUS_ENDPOINT%%";
const PROJECT_UPDATE = "%%PROJECT_UPDATE_ENDPOINT%%";
const ANALYTICS = "%%ANALYTICS_ENDPOINT%%";
const REGION = "%%REGION%%";
const BUCKET = "%%BUCKET%%";

const starter = `<!-- Welcome to the Vibe IDE 🎛️ -->
<!doctype html>
<html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>
<title>My Vibe</title>
<style>body{font-family:IBM Plex Sans,system-ui;background:#0b0d14;color:#e5e7eb;padding:2rem} a{color:#93c5fd}</style></head>
<body><h1>✨ Hello, Vibe!</h1>
<p>Edit this and press <b>Manifest</b> to deploy to your COS bucket.</p>
<p>Public URL will be <code>https://${BUCKET}.${REGION}.cloud-object-storage.appdomain.cloud/index.html</code></p>
<p>Powered by IBM Cloud.</p></body></html>`;

function showBanner(msg, ok=true) { const b=document.getElementById('banner'); b.textContent=(ok?'✅ ':'⚠️ ')+msg; b.style.display='block'; }

const cm = CodeMirror.fromTextArea(document.getElementById('code'), { mode:'xml', theme:'monokai', lineNumbers:true });
cm.setValue(starter);

async function manifest() { const html=cm.getValue();
  showBanner('Deploying…');
  try { await fetch(ANALYTICS, {method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({event:'manifest', REGION})}); } catch(e){}
  const r = await fetch(UPLOAD, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ body: html, key:'index.html' }) });
  const j = await r.json();
  if (j.ok) { showBanner('Deployed! Opening new tab…'); const url=`https://${BUCKET}.${REGION}.cloud-object-storage.appdomain.cloud/index.html`; setTimeout(()=>window.open(url,'_blank'),700); }
  else { showBanner('Upload failed. See console.', false); console.error(j); }
}
async function updateProject() { await fetch(PROJECT_UPDATE, {method:'POST'}); showBanner('Project update request posted. Review in your IBM Cloud Project.'); }
document.getElementById('manifest').addEventListener('click', manifest);
document.getElementById('updateProject').addEventListener('click', updateProject);
document.getElementById('revert').addEventListener('click', ()=> showBanner('Revert coming soon — use previous version in COS if needed.'));
document.getElementById('copyCode').addEventListener('click', ()=> { navigator.clipboard.writeText(cm.getValue()); showBanner('Code copied.'); });
</script></body></html>
"""

def main(params):
    return {"statusCode": 200, "headers": {"Content-Type": "text/html; charset=utf-8"}, "body": INDEX_HTML}
PY
  filename = "${path.module}/vibe_index.py"
}

resource "ibm_function_action" "vibe_manifest" {
  count        = var.enable_functions ? 1 : 0
  action_name  = "vibe-manifest-${random_string.suffix.result}"
  namespace    = var.functions_namespace
  exec { kind = "python:3.11", code = file("${path.module}/vibe_manifest.py") }
  web { enable = true, web_secure = false }
  user_defined_parameters = {
    COS_ACCESS_KEY_ID     = local.cos_access_key
    COS_SECRET_ACCESS_KEY = local.cos_secret_key
    REGION                = local.region
    BUCKET                = local.bucket
  }
}

resource "ibm_function_action" "vibe_status" {
  count        = var.enable_functions ? 1 : 0
  action_name  = "vibe-status-${random_string.suffix.result}"
  namespace    = var.functions_namespace
  exec { kind = "python:3.11", code = file("${path.module}/vibe_status.py") }
  web { enable = true, web_secure = false }
}

resource "ibm_function_action" "vibe_update_project" {
  count        = var.enable_functions ? 1 : 0
  action_name  = "vibe-update-project-${random_string.suffix.result}"
  namespace    = var.functions_namespace
  exec { kind = "python:3.11", code = file("${path.module}/vibe_update_project.py") }
  web { enable = true, web_secure = false }
  user_defined_parameters = {
    COS_ACCESS_KEY_ID     = local.cos_access_key
    COS_SECRET_ACCESS_KEY = local.cos_secret_key
    REGION                = local.region
    BUCKET                = local.bucket
    PROJECT_ID            = var.project_id
  }
}

resource "ibm_function_action" "vibe_analytics" {
  count        = var.enable_functions ? 1 : 0
  action_name  = "vibe-analytics-${random_string.suffix.result}"
  namespace    = var.functions_namespace
  exec { kind = "python:3.11", code = file("${path.module}/vibe_analytics.py") }
  web { enable = true, web_secure = false }
  user_defined_parameters = {
    COS_ACCESS_KEY_ID     = local.cos_access_key
    COS_SECRET_ACCESS_KEY = local.cos_secret_key
    REGION                = local.region
    BUCKET                = local.bucket
    VERSION               = "0.1.0"
  }
}

resource "ibm_function_action" "vibe_index" {
  count        = var.enable_functions ? 1 : 0
  action_name  = "vibe-index-${random_string.suffix.result}"
  namespace    = var.functions_namespace
  exec {
    kind = "python:3.11",
    code = replace(replace(replace(replace(replace(replace(file("${path.module}/vibe_index.py"),
      "%%UPLOAD_ENDPOINT%%", ibm_function_action.vibe_manifest[0].web_action_url),
      "%%STATUS_ENDPOINT%%", ibm_function_action.vibe_status[0].web_action_url),
      "%%PROJECT_UPDATE_ENDPOINT%%", ibm_function_action.vibe_update_project[0].web_action_url),
      "%%ANALYTICS_ENDPOINT%%", ibm_function_action.vibe_analytics[0].web_action_url),
      "%%REGION%%", local.region),
      "%%BUCKET%%", local.bucket)
  }
  web { enable = true, web_secure = false }
  annotations = { "content-type" = "text/html" }
  depends_on  = [ibm_function_action.vibe_manifest, ibm_function_action.vibe_status, ibm_function_action.vibe_update_project, ibm_function_action.vibe_analytics]
}
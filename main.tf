provider "ibm" { region = var.region }

data "ibm_resource_group" "rg" { name = var.resource_group_name }

resource "random_string" "suffix" { length=6 upper=false special=false }

resource "ibm_resource_instance" "cos" {
  name     = "vibe-cos-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
  resource_group_id = data.ibm_resource_group.rg.id
}

resource "ibm_resource_key" "cos_hmac" {
  name                 = "vibe-cos-hmac-${random_string.suffix.result}"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id
  parameters           = { HMAC = true }
}

resource "ibm_cos_bucket" "vibe" {
  bucket_name          = coalesce(var.bucket_name, "vibe-da-${random_string.suffix.result}")
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
  access               = "public"
  website { index_document = "index.html" error_document = "index.html" }
}

locals {
  bucket_public_url = "https://${ibm_cos_bucket.vibe.bucket_name}.${var.region}.cloud-object-storage.appdomain.cloud"
  vibe_id           = "vibe-${random_string.suffix.result}"
}

resource "ibm_function_action" "vibe_upload" {
  name       = "vibe-upload-${random_string.suffix.result}"
  runtime    = "python:3.11"
  publish    = true
  web        = true
  code       = file("${path.module}/vibe_upload.py")
  user_defined_parameters = {
    COS_ACCESS_KEY_ID     = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].access_key_id
    COS_SECRET_ACCESS_KEY = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].secret_access_key
    BUCKET                = ibm_cos_bucket.vibe.bucket_name
    REGION                = var.region
  }
}

resource "ibm_function_action" "vibe_status" {
  name       = "vibe-status-${random_string.suffix.result}"
  runtime    = "python:3.11"
  publish    = true
  web        = true
  code       = file("${path.module}/vibe_status.py")
  user_defined_parameters = {
    URL = "${local.bucket_public_url}/index.html"
  }
}

resource "ibm_function_action" "vibe_project_update" {
  name       = "vibe-project-update-${random_string.suffix.result}"
  runtime    = "python:3.11"
  publish    = true
  web        = true
  code       = file("${path.module}/vibe_upload.py")
  user_defined_parameters = {
    COS_ACCESS_KEY_ID     = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].access_key_id
    COS_SECRET_ACCESS_KEY = jsondecode(ibm_resource_key.cos_hmac.credentials_json).cos_hmac_keys[0].secret_access_key
    BUCKET                = ibm_cos_bucket.vibe.bucket_name
    REGION                = var.region
    PROJECT_MODE          = "update_request"
  }
}

# Render template (replace placeholders with endpoints & ids)
resource "local_file" "index_rendered" {
  filename = "${path.module}/index.html"
  content  = replace(replace(replace(replace(replace(file("${path.module}/index.html"), "%%UPLOAD_ENDPOINT%%", ibm_function_action.vibe_upload.web_action_url), "%%STATUS_ENDPOINT%%", ibm_function_action.vibe_status.web_action_url), "%%PROJECT_UPDATE_ENDPOINT%%", ibm_function_action.vibe_project_update.web_action_url), "%%BUCKET_PUBLIC_URL%%", local.bucket_public_url), "%%VIBE_ID%%", local.vibe_id)
}

resource "null_resource" "bootstrap_upload" {
  triggers = {
    rendered_sha = filesha256(local_file.index_rendered.filename)
    endpoint     = ibm_function_action.vibe_upload.web_action_url
  }
  provisioner "local-exec" {
    command = <<EOC
python3 - <<'PY'
import json, base64, urllib.request
endpoint = "${ibm_function_action.vibe_upload.web_action_url}"
b = open("index.html","rb").read()
payload = json.dumps({"action":"upload","key":"index.html","content_b64":base64.b64encode(b).decode()}).encode()
req = urllib.request.Request(endpoint, data=payload, headers={"Content-Type":"application/json"})
print(urllib.request.urlopen(req, timeout=60).read().decode())
PY
EOC
  }
  depends_on = [ibm_cos_bucket.vibe, ibm_function_action.vibe_upload, local_file.index_rendered]
}


terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {
  # Region used for COS bucket location
  region = var.region
}

data "ibm_resource_group" "default" {
  is_default = true
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# COS instance (Lite)
resource "ibm_resource_instance" "cos" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.default.id
  tags              = ["vibe","da","v1-1-1"]
}

# HMAC key for Functions to write to COS
resource "ibm_resource_key" "cos_hmac" {
  name                 = "vibe-hmac-${random_string.suffix.result}"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id
  parameters           = { HMAC = true }
}

# COS bucket
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
}

# Upload initial index.html
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_resource_instance.cos.id
  bucket_name     = ibm_cos_bucket.bucket.bucket_name
  key             = "index.html"
  content         = file("${path.module}/index.html")
  content_type    = "text/html"
  region_location = var.region
  etag_verify     = false
  depends_on      = [ibm_cos_bucket.bucket]
}

# ---------------- IBM Cloud Functions ----------------
resource "ibm_function_namespace" "ns" {
  name              = "vibe-ns-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.default.id
}

resource "ibm_function_package" "pkg" {
  name        = "vibe"
  namespace   = ibm_function_namespace.ns.name
  publish     = true
  description = "Vibe IDE Functions"
}

# push_to_cos: writes HTML to COS using HMAC creds
resource "ibm_function_action" "push_to_cos" {
  name        = "${ibm_function_package.pkg.name}/push_to_cos"
  namespace   = ibm_function_namespace.ns.name
  description = "Write updated index.html into COS (drift-causing)"
  publish     = true
  web         = true

  exec {
    kind   = "nodejs:default"
    code   = filebase64("${path.module}/functions/push_to_cos.zip")
    binary = true
  }

  parameters = {
    bucket_name = ibm_cos_bucket.bucket.bucket_name
    region      = var.region
    # Endpoint format: s3.<region>.cloud-object-storage.appdomain.cloud
    cos_endpoint = "s3.${var.region}.cloud-object-storage.appdomain.cloud"
    access_key_id     = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["access_key_id"]
    secret_access_key = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["secret_access_key"]
  }
}

# push_to_project: stages HTML to /staged/index.html (safe path).
# NOTE: Projects API wiring can be added later; this function provides a real staging artifact now.
resource "ibm_function_action" "push_to_project" {
  name        = "${ibm_function_package.pkg.name}/push_to_project"
  namespace   = ibm_function_namespace.ns.name
  description = "Stage updated HTML as staged/index.html (Project-friendly)"
  publish     = true
  web         = true

  exec {
    kind   = "nodejs:default"
    code   = filebase64("${path.module}/functions/push_to_project.zip")
    binary = true
  }

  parameters = {
    bucket_name = ibm_cos_bucket.bucket.bucket_name
    region      = var.region
    cos_endpoint = "s3.${var.region}.cloud-object-storage.appdomain.cloud"
    access_key_id     = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["access_key_id"]
    secret_access_key = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["secret_access_key"]
  }
}

# ---------------- Outputs ----------------
output "vibe_url" {
  description = "Open your live site"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "Bucket root"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}

# best-effort web action URLs (OpenWhisk pattern)
output "push_to_cos_url" {
  description = "Web action for pushing HTML directly to COS"
  value       = "https://us-south.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns.name}/${ibm_function_action.push_to_cos.name}"
}

output "push_to_project_url" {
  description = "Web action for staging HTML to /staged/index.html"
  value       = "https://us-south.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns.name}/${ibm_function_action.push_to_project.name}"
}

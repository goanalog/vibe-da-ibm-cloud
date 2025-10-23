
terraform {
  required_version = ">= 1.5.0"
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

# COS instance (Lite plan in a fresh account)
resource "ibm_resource_instance" "cos" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.default.id
  tags              = ["vibe", "starter"]
}

# HMAC resource key for the action
resource "ibm_resource_key" "cos_hmac" {
  name                 = "vibe-hmac-${random_string.suffix.result}"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id
  parameters = {
    HMAC = true
  }
}

# Bucket for website
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
  force_destroy        = true
}

# Upload index.html immediately so site is live even before function is invoked
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_resource_instance.cos.id
  bucket_name     = ibm_cos_bucket.bucket.bucket_name
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("${path.module}/index.html")
  content_type    = "text/html"
  region_location = var.region
  etag_verify     = false
  depends_on      = [ibm_cos_bucket.bucket]
}

# ---------- IBM Cloud Functions (modern schema) ----------

resource "ibm_function_namespace" "ns" {
  name = "vibe-ns-${random_string.suffix.result}"
}

resource "ibm_function_package" "pkg" {
  name        = "vibe-package-${random_string.suffix.result}"
  namespace   = ibm_function_namespace.ns.name
  publish     = true
  description = "Vibe function package"
}

resource "ibm_function_binding" "cos_binding" {
  name         = "cos-binding-${random_string.suffix.result}"
  package      = ibm_function_package.pkg.name
  service_name = ibm_resource_instance.cos.name
}

# Action uploaded as a ZIP artifact (binary) with package.json + code.
# NOTE: Some environments require node_modules to be included; the README covers alternatives.
resource "ibm_function_action" "push_to_cos" {
  name        = "${ibm_function_package.pkg.name}/push_to_cos"
  namespace   = ibm_function_namespace.ns.name
  description = "Uploads index.html to COS using HMAC creds and S3 API."
  publish     = true

  exec {
    kind        = "nodejs:default"
    code        = filebase64("${path.module}/functions/push_to_cos.zip")
    binary      = true
  }

  # Parameters supplied to the action
  parameters = {
    bucket_name            = ibm_cos_bucket.bucket.bucket_name
    html_input             = var.html_input != "" ? var.html_input : file("${path.module}/index.html")
    cos_region             = var.region
    cos_endpoint           = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud"
    hmac_access_key_id     = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["access_key_id"]
    hmac_secret_access_key = ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]["secret_access_key"]
  }

  limits { timeout = 60000 }
}

resource "ibm_function_action_web" "push_to_cos_web" {
  action_name = ibm_function_action.push_to_cos.name
  namespace   = ibm_function_namespace.ns.name
  web_secure  = "false"
}

output "index_html_url" {
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
  description = "Direct URL to index.html"
}

output "push_to_cos_web_action_url" {
  value       = "https://us-south.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns.name}/${ibm_function_action.push_to_cos.name}"
  description = "Web action URL"
}

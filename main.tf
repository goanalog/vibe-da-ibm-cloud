terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

# ---------------------------------------------------------
# Core resources
# ---------------------------------------------------------

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  special = false
  numeric = true
}

locals {
  bucket_name = "${var.bucket_prefix}-${random_string.suffix.result}"
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = local.bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  endpoint_type        = "public"
  force_delete         = true
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"
  key             = "index.html"
  content         = file("${path.module}/index.html")
  force_delete    = true
}

resource "ibm_cos_bucket_object" "page_404" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"
  key             = "404.html"
  content         = <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>404</title>
<style>body{background:#0b0f14;color:#e6f1ff;display:grid;place-items:center;height:100vh;font:16px/1.5 system-ui}
.card{background:#121823;border:1px solid rgba(122,252,255,.35);padding:24px;border-radius:16px}
a{color:#7afcff}</style></head><body>
<div class="card"><h1>404</h1><p>File not found.</p><p><a href="/">Go home</a></p></div>
</body></html>
HTML
  force_delete    = true
}

resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"

  website_configuration {
    index_document { suffix = "index.html" }
    error_document { key = "404.html" }
  }

  depends_on = [
    ibm_cos_bucket_object.index_html,
    ibm_cos_bucket_object.page_404
  ]
}

# ---------------------------------------------------------
# COS writer key (with HMAC)
# ---------------------------------------------------------

resource "ibm_resource_key" "cos_writer" {
  name                 = "vibe-cos-writer-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  role                 = "Writer"

  # FIX: Changed 'parameters_json' to 'parameters' and provided a map
  parameters = {
    HMAC = true
  }
}

# ---------------------------------------------------------
# Cloud Functions (optional)
# ---------------------------------------------------------

resource "ibm_function_namespace" "ns" {
  count             = var.enable_functions ? 1 : 0
  name              = "vibe-ns-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_function_package" "pkg" {
  count     = var.enable_functions ? 1 : 0
  name      = "vibe"
  namespace = ibm_function_namespace.ns[0].id
}

resource "ibm_function_action" "push_to_cos" {
  count     = var.enable_functions ? 1 : 0
  name      = "push_to_cos"
  namespace = ibm_function_namespace.ns[0].id

  exec {
    kind = "nodejs:18"
    code = file("${path.module}/push_to_cos.js")
  }

  # FIX: Combined 'parameter' blocks into one 'parameters' map
  parameters = {
    COS_ENDPOINT      = ibm_cos_bucket.bucket.s3_endpoint_public
    COS_BUCKET        = ibm_cos_bucket.bucket.bucket_name
    COS_REGION        = var.region
    ACCESS_KEY_ID     = ibm_resource_key.cos_writer.credentials["cos_hmac_keys"]["access_key_id"]
    SECRET_ACCESS_KEY = ibm_resource_key.cos_writer.credentials["cos_hmac_keys"]["secret_access_key"]
  }

  depends_on = [ibm_resource_key.cos_writer]
}

resource "ibm_function_action" "push_to_project" {
  count     = var.enable_functions ? 1 : 0
  name      = "push_to_project"
  namespace = ibm_function_namespace.ns[0].id

  exec {
    kind = "nodejs:18"
    code = file("${path.module}/push_to_project.js")
  }

  # FIX: Combined 'parameter' blocks into one 'parameters' map
  parameters = {
    NOTE = "Replace with Schematics trigger later (demo endpoint)"
  }
}

# ---------------------------------------------------------
# Post-apply helper — write injected-vars.txt
# ---------------------------------------------------------

resource "null_resource" "inject_urls" {
  count = var.enable_functions ? 1 : 0

  triggers = {
    cos_url     = ibm_function_action.push_to_cos[0].target_endpoint_url
    project_url = ibm_function_action.push_to_project[0].target_endpoint_url
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "PUSH_COS_URL=${self.triggers.cos_url}" > injected-vars.txt
      echo "PUSH_PROJECT_URL=${self.triggers.project_url}" >> injected-vars.txt
      echo "✨ Injected function URLs into injected-vars.txt"
    EOT
  }

  depends_on = [
    ibm_function_action.push_to_cos,
    ibm_function_action.push_to_project
  ]
}
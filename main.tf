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
  region = var.region
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# COS instance
resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

# COS bucket
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true

  website {
    enable    = true
    mainpage  = "index.html"
    errorpage = "404.html"
  }
}

# IBM Cloud Functions namespace + package
resource "ibm_function_namespace" "ns" {
  name = "vibe-ns-${random_string.suffix.result}"
}

resource "ibm_function_package" "pkg" {
  name      = "vibe-funcs-${random_string.suffix.result}"
  namespace = ibm_function_namespace.ns.name
}

# Functions (Node.js:18 zips)
resource "ibm_function_action" "push_to_cos" {
  name      = "push_to_cos"
  namespace = ibm_function_namespace.ns.name
  package   = ibm_function_package.pkg.name
  exec_kind = "nodejs:18"
  code_path = "${path.module}/functions/push_to_cos.zip"
}

resource "ibm_function_action" "push_to_project" {
  name      = "push_to_project"
  namespace = ibm_function_namespace.ns.name
  package   = ibm_function_package.pkg.name
  exec_kind = "nodejs:18"
  code_path = "${path.module}/functions/push_to_project.zip"
}

# Live URLs for injection
locals {
  push_cos_url     = ibm_function_action.push_to_cos.invoke_url
  push_project_url = ibm_function_action.push_to_project.invoke_url
}

# Upload an HTML page with live Function URLs injected
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn   = ibm_cos_bucket.bucket.crn
  key          = "index.html"
  content      = base64encode(
    templatefile("${path.module}/samples/index.html", {
      PUSH_COS_URL     = local.push_cos_url
      PUSH_PROJECT_URL = local.push_project_url
    })
  )
  content_type = "text/html"
}

# (Optional) A 404 page to avoid ugly errors
resource "ibm_cos_bucket_object" "page_404" {
  bucket_crn   = ibm_cos_bucket.bucket.crn
  key          = "404.html"
  content      = base64encode("<!doctype html><html><head><meta charset=\"utf-8\"><title>404</title></head><body style=\"font-family:sans-serif; background:#0b1020; color:#e2e8f0\"><h1>404 — the vibe you seek is elsewhere</h1><p><a href=\"/\">Return to the Vibe IDE</a></p></body></html>")
  content_type = "text/html"
}

output "vibe_url" {
  value       = ibm_cos_bucket.bucket.website_url
  description = "Primary Vibe site URL (promoted output)"
}

output "vibe_bucket_url" {
  value = ibm_cos_bucket.bucket.website_url
}

output "push_cos_url" {
  value       = local.push_cos_url
  description = "Live IBM Cloud Function URL for Push-to-COS"
}

output "push_project_url" {
  value       = local.push_project_url
  description = "Live IBM Cloud Function URL for Push-to-Project"
}

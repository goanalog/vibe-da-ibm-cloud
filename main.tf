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
  }
}

provider "ibm" {}

# Look up the resource group
data "ibm_resource_group" "group" {
  name = var.resource_group
}

# COS instance (Lite)
resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-cos-${var.region}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

# Random suffix for globally-unique bucket name
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  number  = true
  special = false
}

# Public bucket (static hosting)
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
  endpoint_type        = "public"
}

# Website configuration (index + 404)
resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"

  website_configuration {
    index_document {
      suffix = "index.html"
    }
    error_document {
      key = "404.html"
    }
  }
}

# Upload index.html
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = file("${path.module}/index.html")
  endpoint_type   = "public"
  force_delete    = true

  depends_on = [ibm_cos_bucket_website_configuration.bucket_website]
}

# Upload 404.html
resource "ibm_cos_bucket_object" "page_404" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "404.html"
  content         = file("${path.module}/404.html")
  endpoint_type   = "public"
  force_delete    = true

  depends_on = [ibm_cos_bucket_website_configuration.bucket_website]
}

# --- Functions (enabled by default) ---

locals {
  enable_functions = var.enable_functions
}

# Authorization policy: allow Cloud Functions -> COS write
resource "ibm_iam_authorization_policy" "functions_to_cos" {
  count = local.enable_functions ? 1 : 0

  source_service_name = "cloud-functions"
  target_service_name = "cloud-object-storage"
  roles               = ["Writer"]

  description = "Permit Cloud Functions to write to COS for Vibe deploys"
}

# Create a COS resource key with HMAC for programmatic access (Writer)
resource "ibm_resource_key" "cos_writer" {
  count               = local.enable_functions ? 1 : 0
  name                = "vibe-cos-writer-${random_string.suffix.result}"
  role                = "Writer"
  service_instance_id = ibm_resource_instance.cos_instance.id

  parameters = {
    HMAC = true
  }
}

# Functions namespace
resource "ibm_function_namespace" "ns" {
  count              = local.enable_functions ? 1 : 0
  name               = "vibe-${random_string.suffix.result}"
  resource_group_id  = data.ibm_resource_group.group.id
}

# Package (optional container for actions)
resource "ibm_function_package" "pkg" {
  count     = local.enable_functions ? 1 : 0
  name      = "vibe"
  publish   = false
  namespace = ibm_function_namespace.ns[0].name
}

# Action: push_to_cos (actually uploads content to the bucket)
resource "ibm_function_action" "push_to_cos" {
  count     = local.enable_functions ? 1 : 0
  name      = "push_to_cos"
  namespace = ibm_function_namespace.ns[0].name

  exec {
    kind = "nodejs:18"
    code = file("${path.module}/push_to_cos.js")
  }

  # Parameters (wired from the COS resource key)
  parameters_json = jsonencode({
    COS_BUCKET_NAME     = ibm_cos_bucket.bucket.bucket_name
    COS_REGION          = var.region
    COS_RESOURCE_CRN    = ibm_resource_instance.cos_instance.crn
    COS_HMAC_ACCESS_KEY = ibm_resource_key.cos_writer[0].credentials["cos_hmac_keys"]["access_key_id"]
    COS_HMAC_SECRET_KEY = ibm_resource_key.cos_writer[0].credentials["cos_hmac_keys"]["secret_access_key"]
  })
}

# Action: push_to_project (placeholder – returns OK; swap with your logic)
resource "ibm_function_action" "push_to_project" {
  count     = local.enable_functions ? 1 : 0
  name      = "push_to_project"
  namespace = ibm_function_namespace.ns[0].name

  exec {
    kind = "nodejs:18"
    code = file("${path.module}/push_to_project.js")
  }

  # Example params you might want to wire later
  parameters_json = jsonencode({
    NOTE = "Replace with your Schematics/Project trigger call"
  })
}

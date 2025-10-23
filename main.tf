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

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-cos-${var.region}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  endpoint_type        = "public"
  force_delete         = true
}

resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"

  website_configuration {
    index_document { suffix = "index.html" }
    error_document { key = "404.html" }
  }
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = file("${path.module}/index.html")
  endpoint_type   = "public"
  force_delete    = true
  depends_on      = [ibm_cos_bucket_website_configuration.bucket_website]
}

locals {
  enable_functions = var.enable_functions
}

resource "ibm_iam_authorization_policy" "functions_to_cos" {
  count = local.enable_functions ? 1 : 0

  source_service_name = "cloud-functions"
  target_service_name = "cloud-object-storage"
  roles               = ["Writer"]
}

resource "ibm_resource_key" "cos_writer" {
  count                = local.enable_functions ? 1 : 0
  name                 = "vibe-cos-writer-${random_string.suffix.result}"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  parameters = {
    HMAC = true
  }
}

resource "ibm_function_namespace" "ns" {
  count             = local.enable_functions ? 1 : 0
  name              = "vibe-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_function_package" "pkg" {
  count     = local.enable_functions ? 1 : 0
  name      = "vibe"
  namespace = ibm_function_namespace.ns[0].name
  publish   = false
}

# push_to_cos function
resource "ibm_function_action" "push_to_cos" {
  count     = local.enable_functions ? 1 : 0
  name      = "push_to_cos"
  namespace = ibm_function_namespace.ns[0].name

  exec {
    kind = "nodejs:18"
    code = file("${path.module}/push_to_cos.js")
  }

  parameters = jsonencode({
    COS_BUCKET_NAME     = ibm_cos_bucket.bucket.bucket_name
    COS_REGION          = var.region
    COS_RESOURCE_CRN    = ibm_resource_instance.cos_instance.crn
    COS_HMAC_ACCESS_KEY = i_

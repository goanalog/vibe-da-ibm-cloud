terraform {
  required_version = ">= 1.4.0"
  required_providers {
    ibm = { source = "ibm-cloud/ibm", version = ">= 1.84.0" }
    random = { source = "hashicorp/random", version = ">= 3.0.0" }
    time = { source = "hashicorp/time", version = ">= 0.9.1" }
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
  number  = true
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.bucket_prefix}-cos-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  endpoint_type        = "public"
  force_delete         = true
}

resource "time_sleep" "after_bucket" {
  depends_on      = [ibm_cos_bucket.bucket]
  create_duration = "20s"
}

resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  depends_on      = [time_sleep.after_bucket]
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
  content         = base64encode(file("${path.module}/index.html"))
  endpoint_type   = "public"
  force_delete    = true
  depends_on      = [ibm_cos_bucket_website_configuration.bucket_website]
}

locals { enable_functions = var.enable_functions }

resource "ibm_function_namespace" "ns" {
  count             = local.enable_functions ? 1 : 0
  name              = "vibe-ns-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
  location          = var.region
}

resource "ibm_function_package" "pkg" {
  count      = local.enable_functions ? 1 : 0
  name       = "vibe"
  namespace  = ibm_function_namespace.ns[0].name
  publish    = false
}

resource "ibm_function_action" "push_to_cos" {
  count      = local.enable_functions ? 1 : 0
  name       = "push_to_cos"
  namespace  = ibm_function_namespace.ns[0].name
  kind       = "nodejs:18"
  exec { code_path = "${path.module}/push_to_cos.zip", kind = "nodejs:18" }
  annotations = { "web-export" = true }
}

resource "ibm_function_action" "push_to_project" {
  count     = local.enable_functions ? 1 : 0
  name      = "push_to_project"
  namespace = ibm_function_namespace.ns[0].name
  exec { code_path = "${path.module}/push_to_project.zip", kind = "nodejs:18" }
  annotations = { "web-export" = true }
}

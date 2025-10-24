terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.3"
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

# Random suffix for uniqueness
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Object Storage instance (Lite plan)
resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = var.resource_group_id
}

# Create COS bucket
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
  # --- FIX: Removed unsupported website arguments ---
}

# Upload index.html
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = file("${path.module}/index.html")
  content_type    = "text/html"
}

# Upload error page
resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = var.region
  key             = "404.html"
  content         = file("${path.module}/404.html")
  content_type    = "text/html"
}

# Optional: enable IBM Cloud Functions namespace
resource "ibm_function_namespace" "vibe_namespace" {
  count             = var.enable_functions ? 1 : 0
  name              = "vibe-namespace-${random_string.suffix.result}"
  resource_group_id = var.resource_group_id
}

# Push to COS Function Action
resource "ibm_function_action" "push_to_cos" {
  count     = var.enable_functions ? 1 : 0
  name      = "push-to-cos-${random_string.suffix.result}"
  namespace = ibm_function_namespace.vibe_namespace[0].name
  publish   = true

  exec {
    kind = "nodejs:18"
    code = filebase64("${path.module}/push_to_cos.js")
  }
}

# Push to Project Function Action
resource "ibm_function_action" "push_to_project" {
  count     = var.enable_functions ? 1 : 0
  name      = "push-to-project-${random_string.suffix.result}"
  namespace = ibm_function_namespace.vibe_namespace[0].name
  publish   = true

  exec {
    kind = "nodejs:18"
    code = filebase64("${path.module}/push_to_project.js")
  }
}
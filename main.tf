###############################################################################
# Vibe IDE — Max Vibe Edition
# Deploys an IBM Cloud Object Storage (Lite) bucket and optional Cloud Functions
# to push updates to COS or to an IBM Cloud Project.
###############################################################################

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
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
  required_version = ">= 1.3.0"
}

provider "ibm" {
  region = var.region
}

###############################################################################
# Resource group input (embedded for Catalog compatibility)
###############################################################################
variable "resource_group_id" {
  description = "ID of the IBM Cloud resource group to deploy into (defaults to the user's default resource group)"
  type        = string
  default     = ""
}


resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = var.resource_group_id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name           = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  region_location       = var.region
  storage_class         = "standard"
  force_delete          = true

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  region_location       = var.region
  storage_class         = "standard"
  force_delete          = true
  website_endpoint_enabled = true
  website_error_document    = "404.html"
  website_index_document    = "index.html"
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn = ibm_cos_bucket.vibe_bucket.crn
  key        = "index.html"
  content    = file("${path.module}/index.html")
  content_type = "text/html"
}

resource "ibm_cos_bucket_object" "error_html" {
  bucket_crn = ibm_cos_bucket.vibe_bucket.crn
  key        = "404.html"
  content    = file("${path.module}/404.html")
  content_type = "text/html"
}

resource "ibm_function_namespace" "vibe_namespace" {
  name              = "vibe-namespace-${random_string.suffix.result}"
  resource_group_id = var.resource_group_id
}"
}

resource "ibm_function_action" "push_to_cos" {
  name        = "push_to_cos"
  namespace   = ibm_function_namespace.vibe_namespace.name
  exec_kind   = "nodejs:18"
  exec_code   = file("${path.module}/push_to_cos.js")

  parameters = [
    { name = "COS_ENDPOINT",      value = var.cos_endpoint },
    { name = "COS_BUCKET",        value = ibm_cos_bucket.vibe_bucket.bucket_name },
    { name = "COS_REGION",        value = var.region },
    { name = "ACCESS_KEY_ID",     value = var.cos_access_key },
    { name = "SECRET_ACCESS_KEY", value = var.cos_secret_key }
  ]
}

resource "ibm_function_action" "push_to_project" {
  name        = "push_to_project"
  namespace   = ibm_function_namespace.vibe_namespace.name
  exec_kind   = "nodejs:18"
  exec_code   = file("${path.module}/push_to_project.js")

  parameters = [
    { name = "NOTE", value = "Triggered by Vibe IDE — Max Vibe Edition" }
  ]
}

output "vibe_bucket_name" {
  description = "Name of the deployed COS bucket"
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

output "vibe_bucket_website_endpoint" {
  description = "URL of the static website hosted in IBM Cloud Object Storage"
  value       = ibm_cos_bucket.vibe_bucket.website_endpoint
}

output "push_to_cos_url" {
  description = "Cloud Function URL to push updates to COS"
  value       = ibm_function_action.push_to_cos.action_url
}

output "push_to_project_url" {
  description = "Cloud Function URL to push updates to IBM Cloud Project"
  value       = ibm_function_action.push_to_project.action_url
}

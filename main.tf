# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Deployable Architecture — "Instant Vibe Coder"
# Version: 0.1.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "ibm" {}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_plan == "lite" ? "global" : var.region
  resource_group_id = data.ibm_resource_group.group.id

  tags = ["vibe", "vibe-coder", "deployable-architecture", "sample"]

  parameters = {
    service-endpoints = "public"
  }
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name           = "${var.cos_bucket_name}-${random_string.suffix.result}"
  region_location       = var.region
  storage_class         = "standard"
  resource_instance_id  = ibm_resource_instance.cos_instance.id
  force_delete          = true
  object_lock_enabled   = false
  access                = var.public_access ? "public" : "private"
}

locals {
  vibe_app_content = var.vibe_code != "" ? var.vibe_code : file("${path.module}/index.html")
}

resource "ibm_cos_bucket_object" "vibe_app" {
  bucket_crn   = ibm_cos_bucket.vibe_bucket.crn
  key          = "index.html"
  content      = local.vibe_app_content
  content_type = "text/html"
}

output "vibe_bucket_url" {
  description = "Direct public URL of the hosted Vibe app"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

output "vibe_url" {
  description = "Alias for the main app URL"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
}

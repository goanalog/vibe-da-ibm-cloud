# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Code Landing Zone — Terraform Deployable Architecture
# Version: 1.0.2
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

# --- Create Resource Group (auto-create if missing) ---
resource "ibm_resource_group" "group" {
  name = var.resource_group
}

# --- Random suffix for uniqueness ---
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- Create COS Instance (always global) ---
resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = ibm_resource_group.group.id

  tags = ["vibe", "static-website", "deployable-architecture", "ibm-cloud"]
}

# --- Create COS Bucket ---
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
}

# --- Inline or sample HTML ---
locals {
  index_html = var.index_html != "" ? var.index_html : file("${path.module}/index.html")
}

# --- Upload HTML file ---
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = local.index_html
  etag            = md5(local.index_html)
}

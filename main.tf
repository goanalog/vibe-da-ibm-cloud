# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Code Landing Zone — Terraform Deployable Architecture
# Version: 1.0.0
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

# --- Resource Group ---
data "ibm_resource_group" "group" {
  name = var.resource_group
}

# --- Random Suffix for Unique Names ---
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- COS Instance ---
resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["vibe", "deployable-architecture", "static-website"]
}

# --- COS Bucket ---
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"

  dynamic "access" {
    for_each = var.public_access ? [1] : []
    content {
      type = "public"
    }
  }
}

# --- Upload HTML (either inline or sample) ---
locals {
  index_html = var.index_html != "" ? var.index_html : file("${path.module}/index.html")
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn = ibm_cos_bucket.bucket.crn
  key        = "index.html"
  content    = local.index_html
  etag       = md5(local.index_html)
}

# --- Outputs ---
output "vibe_bucket_url" {
  description = "Direct link to your sacred bucket."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}

output "vibe_url" {
  description = "Behold the consecrated endpoint for direct vibe consumption."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

# --- Variables ---
variable "region" {
  description = "IBM Cloud region (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group name."
  type        = string
  default     = "default"
}

variable "cos_instance_name" {
  description = "Friendly name for your IBM Cloud Object Storage instance."
  type        = string
  default     = "vibe-coder-cos"
}

variable "bucket_name" {
  description = "Base name for your COS bucket (lowercase, no spaces)."
  type        = string
  default     = "vibe-coder-sample-bucket"
}

variable "index_html" {
  description = "Inline HTML code pasted by the user."
  type        = string
  default     = ""
}

variable "public_access" {
  description = "Whether to make the bucket publicly readable (recommended for hosting)."
  type        = bool
  default     = true
}

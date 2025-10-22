# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Vibe Manifestation Engine v1.1
#  Terraform logic to manifest a user’s pasted HTML (or default sample app)
#  into an IBM Cloud Object Storage bucket with base64 auto-handling.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.62.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "ibm" {}

data "ibm_resource_group" "group" {
  name = "Default"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "vibe_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name         = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = var.region
  force_delete         = true
}

locals {
  html_content = (
    length(trimspace(var.vibe_html_input)) > 0 ?
    var.vibe_html_input :
    file("${path.module}/index.html")
  )

  html_base64 = base64encode(local.html_content)
}

resource "ibm_cos_object" "vibe_app" {
  bucket          = ibm_cos_bucket.vibe_bucket.bucket_name
  key             = "index.html"
  content_base64  = local.html_base64
  content_type    = "text/html"
}

output "vibe_url" {
  description = "Your live Vibe App URL (public endpoint)"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "vibe_bucket_url" {
  description = "Raw COS bucket URL"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/"
}

output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

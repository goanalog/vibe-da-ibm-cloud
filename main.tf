terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.62.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

resource "ibm_resource_instance" "vibe_instance" {
  name     = var.vibe_instance_name
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "${var.vibe_bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

locals {
  escaped_html = replace(
    replace(
      replace(
        replace(
          replace(trimspace(var.html_input), "&", "&amp;"),
        "<", "&lt;"),
      ">", "&gt;"),
    "\"", "&quot;"),
  "'", "&#39;")
}

resource "local_file" "html_file" {
  filename = "${path.module}/rendered_index.html"
  content  = var.html_input != "" ? local.escaped_html : file("${path.module}/index.html")
}

resource "ibm_cos_bucket_object" "html" {
  bucket  = ibm_cos_bucket.vibe_bucket.bucket_name
  key     = "index.html"
  content = file(local_file.html_file.filename)
}

output "vibe_bucket_url" {
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud"
  description = "Public bucket URL"
}

output "vibe_url" {
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
  description = "Public URL for your vibe app"
}

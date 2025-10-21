# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ✨ Vibe Manifestation Engine v1.1 — Public Edition ✨
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ibm   = { source = "IBM-Cloud/ibm", version = ">= 1.58.0" }
    local = { source = "hashicorp/local", version = ">= 2.5.0" }
  }
}

provider "ibm" { region = var.region }

locals {
  html_content = var.index_html != "" ?
    var.index_html :
    (var.index_html_file != "" ?
      file(var.index_html_file) :
      "<!DOCTYPE html><html><body><h1>🌈 Awaiting your vibe...</h1></body></html>")
}

resource "ibm_resource_instance" "cos" {
  name           = var.cos_instance_name
  service        = "cloud-object-storage"
  plan           = "lite"
  location       = var.region
  resource_group = var.resource_group
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = var.bucket_name
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
  force_destroy        = true
}

resource "ibm_cos_bucket_object" "index" {
  bucket_crn    = ibm_resource_instance.cos.id
  bucket_name   = ibm_cos_bucket.bucket.bucket_name
  key           = "index.html"
  content       = local.html_content
  content_type  = "text/html"
}

resource "ibm_cos_bucket_object" "plan_md" {
  bucket_crn    = ibm_resource_instance.cos.id
  bucket_name   = ibm_cos_bucket.bucket.bucket_name
  key           = "sacred_scrolls/PLAN.md"
  content = <<-EOT
    # 🌿 Vibe Plan Scroll
    - Region: ${var.region}
    - Bucket: ${var.bucket_name}
    - Instance: ${var.cos_instance_name}
    - Generated: ${timestamp()}
  EOT
  content_type = "text/markdown"
}

resource "ibm_cos_bucket_object" "synergy_realized_md" {
  bucket_crn    = ibm_resource_instance.cos.id
  bucket_name   = ibm_cos_bucket.bucket.bucket_name
  key           = "sacred_scrolls/SYNERGY_REALIZED.md"
  content = <<-EOT
    ## ✨ Synergy Realized ✨
    Manifested on ${timestamp()} UTC in ${var.region}.
  EOT
  content_type = "text/markdown"
}

output "vibe_url" {
  description = "Behold the consecrated endpoint for direct vibe consumption."
  value       = "https://${var.bucket_name}.s3-web.${var.region}.cloud-object-storage.appdomain.cloud/"
}

output "vibe_bucket_url" {
  description = "Direct link to your sacred bucket."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${var.bucket_name}/"
}

# Enable static website hosting for the bucket
resource "ibm_cos_bucket_website_config" "website" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  index_document  = "index.html"
  error_document  = "index.html"
}
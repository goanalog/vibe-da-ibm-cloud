# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Manifestation Engine v1.1.1 — Auto-Encoding Edition (Catalog-Safe)
# Transmutes raw HTML pasted by the user into a live, hosted web experience.
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

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "vibe_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
}

resource "ibm_cos_bucket" "vibe" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = var.region
  storage_class        = "standard"
}

resource "ibm_cos_object" "vibe_html" {
  bucket          = ibm_cos_bucket.vibe.bucket_name
  key             = "index.html"
  content_base64  = local.vibe_code_b64
  content_type    = "text/html"
}

resource "ibm_cos_bucket_policy" "public_policy" {
  bucket = ibm_cos_bucket.vibe.bucket_name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::${ibm_cos_bucket.vibe.bucket_name}/*"]
    }
  ]
}
POLICY
}

output "vibe_bucket_name" {
  value = ibm_cos_bucket.vibe.bucket_name
}

output "vibe_url" {
  description = "Public URL of your manifested vibe"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

output "primaryoutputlink" {
  description = "Primary output link for IBM Cloud Projects"
  value       = "https://${ibm_cos_bucket.vibe.bucket_name}.s3.${var.region}.cloud-object-storage.appdomain.cloud/index.html"
}

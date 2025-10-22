# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Manifestation Engine v1.1.2 — Auto-Encoding, Modular, Catalog-Safe Edition
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

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# IBM COS instance (Lite)
resource "ibm_resource_instance" "vibe_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
}

# COS bucket for hosting the site
resource "ibm_cos_bucket" "vibe" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = var.region
  storage_class        = "standard"
}

# Upload encoded HTML content
resource "ibm_cos_object" "vibe_html" {
  bucket          = ibm_cos_bucket.vibe.bucket_name
  key             = "index.html"
  content_base64  = local.vibe_code_b64
  content_type    = "text/html"
}

# Make the bucket publicly readable
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

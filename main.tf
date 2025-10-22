# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Manifestation Engine v0.1.0
# Safely accepts arbitrary HTML input (auto Base64-encoded by IBM Cloud Projects),
# decodes it, and deploys it as a public static website on IBM Cloud Object Storage.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

# ------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# COS instance
resource "ibm_resource_instance" "vibe_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = var.resource_group_id
}

# COS bucket
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id  = ibm_resource_instance.vibe_instance.id
  region_location       = var.region
  storage_class         = "standard"
  force_delete          = true
}

# Decode Base64 HTML and upload as index.html
locals {
  decoded_html = base64decode(var.html_input_b64)
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket   = ibm_cos_bucket.vibe_bucket.bucket_name
  key      = "index.html"
  content  = local.decoded_html
  etag     = md5(local.decoded_html)
}

# Make bucket publicly readable
resource "ibm_cos_bucket_policy" "public_read" {
  bucket_name = ibm_cos_bucket.vibe_bucket.bucket_name
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["arn:aws:s3:::${ibm_cos_bucket.vibe_bucket.bucket_name}/*"]
    }]
  })
}

# ------------------------------------------------------------------------------

# Primary and secondary outputs
output "primary_output" {
  description = "Primary URL output promoted in IBM Cloud Projects"
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.${var.region}.digitaloceanspaces.com/index.html"
}

output "vibe_url" {
  description = "Public URL of your deployed HTML app."
  value       = "https://${ibm_cos_bucket.vibe_bucket.bucket_name}.${var.region}.digitaloceanspaces.com/index.html"
}

output "vibe_bucket_name" {
  description = "Name of the IBM COS bucket hosting your vibe."
  value       = ibm_cos_bucket.vibe_bucket.bucket_name
}

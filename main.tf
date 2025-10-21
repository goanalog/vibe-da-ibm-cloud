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

provider "ibm" {
  region = var.region
}

# ---------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------
locals {
  html_content = (
    length(trimspace(var.index_html)) > 0 ? var.index_html :
    (length(trimspace(var.index_html_file)) > 0 ? file(var.index_html_file) : file("${path.module}/index.html"))
  )
}

# ---------------------------------------------------------------------
# Random Suffix
# ---------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ---------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------
data "ibm_resource_group" "selected" {
  name = var.resource_group
}

# ---------------------------------------------------------------------
# COS Instance
# ---------------------------------------------------------------------
resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.selected.id
}

# ---------------------------------------------------------------------
# COS Bucket
# ---------------------------------------------------------------------
resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

# ---------------------------------------------------------------------
# Upload the index.html
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "index_html" {
  # --- FIX 1: Replaced 'bucket' with 'bucket_crn' ---
  bucket_crn = ibm_cos_bucket.bucket.crn
  # --- FIX 2: Added 'bucket_location' ---
  bucket_location = ibm_cos_bucket.bucket.region_location
  
  key          = "index.html"
  content      = local.html_content
  content_type = "text/html"
  depends_on   = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# Upload the vibe-face.png asset
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_object" "vibe_face" {
  # --- FIX 1: Replaced 'bucket' with 'bucket_crn' ---
  bucket_crn = ibm_cos_bucket.bucket.crn
  # --- FIX 2: Added 'bucket_location' ---
  bucket_location = ibm_cos_bucket.bucket.region_location
  
  key = "vibe-face.png"
  
  # --- FIX 3: Changed 'file' to 'content(file(...))' ---
  content      = file("${path.module}/vibe-face.png")
  content_type = "image/png"
  depends_on   = [ibm_cos_bucket.bucket]
}

# ---------------------------------------------------------------------
# Make the bucket public (Restoring original policy block)
# ---------------------------------------------------------------------
resource "ibm_cos_bucket_policy" "public_access" {
  bucket_name          = ibm_cos_bucket.bucket.bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance.id

  policy = <<EOT
{
  "Version": "2.0",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::${ibm_cos_bucket.bucket.bucket_name}/*"]
    }
  ]
}
EOT

  depends_on = [ibm_cos_bucket.bucket]
}
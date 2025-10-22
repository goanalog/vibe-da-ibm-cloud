# Configure the IBM Cloud Provider
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.60.0" # Use a recent version
    }
  }
}

# Create the COS (Cloud Object Storage) instance
# This uses the "lite" plan, which is free, as described in the Readme.
resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = var.resource_group_id
}

# Create the COS bucket
# Note: Bucket names must be globally unique.
resource "ibm_cos_bucket" "cos_bucket" {
  bucket_name          = var.bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"

  # This is the magic that makes it a public website
  website_configuration {
    index_document = "index.html"
  }
}

# Set the public access policy for the bucket
resource "ibm_cos_bucket_public_access" "public_access" {
  bucket_name = ibm_cos_bucket.cos_bucket.bucket_name
  public_access = "public-read"
}

# Determine which HTML content to use
locals {
  # If the user provides HTML, use it. Otherwise, use the sample app file.
  html_to_deploy = var.vibe_html_content != "" ? var.vibe_html_content : file("${path.module}/index.html")
}

# Upload the index.html file to the bucket
resource "ibm_cos_bucket_object" "index_object" {
  bucket_name    = ibm_cos_bucket.cos_bucket.bucket_name
  key            = "index.html"
  content_type   = "text/html"
  content        = local.html_to_deploy
  
  # Ensure public access is set before uploading
  depends_on = [ibm_cos_bucket_public_access.public_access]
}
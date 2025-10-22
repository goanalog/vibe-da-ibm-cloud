#############################
# Providers / Constants
#############################
provider "ibm" {}

locals {
  region               = "us-south"
  resource_group_name  = "Default"
  bucket_name_prefix   = "vibe-bucket-"
  instance_name_prefix = "vibe-instance-"
  website_key          = "index.html"
  public_read          = true
}

data "ibm_resource_group" "rg" {
  name = local.resource_group_name
}

#############################
# Random suffix for uniqueness
#############################
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

#############################
# COS Instance (Lite)
#############################
resource "ibm_resource_instance" "vibe_instance" {
  name              = "${local.instance_name_prefix}${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.rg.id
  tags              = ["vibe", "deployable-architecture"]
}

#############################
# COS Bucket
#############################
resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "${local.bucket_name_prefix}${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = local.region
  storage_class        = "smart"
  force_delete         = true
}

#############################
# Website hosting
#############################
resource "ibm_cos_bucket_website" "site" {
  bucket          = ibm_cos_bucket.vibe_bucket.bucket_name
  index_document  = local.website_key
  error_document  = local.website_key
}

#############################
# Safe HTML auto-encoding logic (HTML or Base64)
#############################
locals {
  vibe_is_base64 = can(regex("^[A-Za-z0-9+/=]+$", trimspace(var.vibe_code))) && length(trimspace(var.vibe_code)) > 200

  vibe_html_base64 = trim(var.vibe_code) == "" ? base64encode(file("${path.module}/index.html")) :
                     local.vibe_is_base64 ? var.vibe_code :
                     base64encode(var.vibe_code)
}

#############################
# Upload
#############################
resource "ibm_cos_object" "vibe_app" {
  bucket         = ibm_cos_bucket.vibe_bucket.bucket_name
  key            = local.website_key
  content_base64 = local.vibe_html_base64
  content_type   = "text/html"
}

#############################
# Public read policy
#############################
resource "ibm_cos_bucket_policy" "public_read" {
  count  = local.public_read ? 1 : 0
  bucket = ibm_cos_bucket.vibe_bucket.bucket_name
  policy = jsonencode({
    "Version"   : "2012-10-17",
    "Statement" : [{
      "Sid"       : "PublicReadGetObject",
      "Effect"    : "Allow",
      "Principal" : "*",
      "Action"    : ["s3:GetObject"],
      "Resource"  : [
        "crn:v1:bluemix:public:cloud-object-storage:global::::bucket:${ibm_cos_bucket.vibe_bucket.bucket_name}/object/*"
      ]
    }]
  })
}

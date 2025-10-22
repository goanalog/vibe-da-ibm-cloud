#############################
# Providers / Data
#############################
provider "ibm" {}

data "ibm_resource_group" "rg" {
  name = var.resource_group
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
  name              = "${var.instance_name_prefix}${random_string.suffix.result}"
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
  bucket_name          = "${var.bucket_name_prefix}${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  region_location      = var.region
  storage_class        = "smart"
  force_delete         = true
}

#############################
# Website hosting
#############################
resource "ibm_cos_bucket_website" "site" {
  bucket          = ibm_cos_bucket.vibe_bucket.bucket_name
  index_document  = var.website_key
  error_document  = var.website_key
}

#############################
# HTML content: take input or fall back to local file
#############################
locals {
  html_source  = trim(var.vibe_code) != "" ? var.vibe_code : file("${path.module}/index.html")
  html_base64  = base64encode(local.html_source)
}

resource "ibm_cos_object" "vibe_app" {
  bucket         = ibm_cos_bucket.vibe_bucket.bucket_name
  key            = var.website_key
  content_base64 = local.html_base64
  content_type   = "text/html"
}

#############################
# Optional: Public read policy for website
#############################
resource "ibm_cos_bucket_policy" "public_read" {
  count  = var.public_read ? 1 : 0
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

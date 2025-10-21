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

locals {
  html_content = var.index_html != "" ? var.index_html : file(var.index_html_file)
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

data "ibm_resource_group" "selected" {
  name = var.resource_group
}

resource "ibm_resource_instance" "cos_instance" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.selected.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

resource "ibm_cos_object" "index_html" {
  bucket        = ibm_cos_bucket.bucket.bucket_name
  key           = "index.html"
  content       = local.html_content
  content_type  = "text/html"
}

resource "ibm_cos_object" "vibe_face" {
  bucket        = ibm_cos_bucket.bucket.bucket_name
  key           = "vibe-face.png"
  source        = "vibe-face.png"
  content_type  = "image/png"
}

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
}

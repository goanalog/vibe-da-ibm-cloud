
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  number  = true
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = var.cos_plan
  location = "global"
  tags     = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  region_location      = var.region
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class        = "standard"
  endpoint_type        = "public"
  force_delete         = true
}

resource "ibm_cos_bucket_policy" "public_read" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = ibm_cos_bucket.bucket.region_location
  policy          = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["arn:aws:s3:::${ibm_cos_bucket.bucket.bucket_name}/*"]
    }]
  })
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = var.index_html != "" ? var.index_html : file("${path.module}/index.html")
  endpoint_type   = "public"
  force_delete    = true
}

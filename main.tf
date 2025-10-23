# main.tf

provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  html_content = var.vibe_code_raw != "" ?
  var.vibe_code_raw : file("${path.module}/index.html")
}

resource "ibm_resource_instance" "vibe_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = "global"
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = "us-south"
  force_delete         = true
}

resource "ibm_cos_bucket_object" "vibe_code" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location

  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)
  
  # This makes the individual object public, fixing the 403 error
  acl = "public-read"
}
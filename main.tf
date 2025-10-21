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
  numeric = true
  special = false
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name        = "${var.bucket_name}-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class      = "standard"
  allowed_ip         = ["0.0.0.0/0"]
  acl                = "public-read"
}

resource "ibm_cos_bucket_object" "index" {
  bucket_crn = ibm_cos_bucket.bucket.crn
  key        = "index.html"
  content    = var.index_html != "" ? var.index_html : file("${path.module}/index.html")
  etag       = md5(var.index_html)
}

output "vibe_url" {
  description = "Public URL for your vibe app."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
}

output "vibe_bucket_url" {
  description = "Direct bucket URL."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}

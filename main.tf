terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  number  = true
  special = false
}

locals {
  resolved_bucket_name = "${var.bucket_name}-${random_string.suffix.result}"
  resolved_index_html  = trimspace(var.index_html) != "" ? var.index_html : file("${path.module}/index.html")
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = local.resolved_bucket_name
  resource_instance_id = ibm_resource_instance.cos_instance.id

  region_location = var.region
  storage_class   = "standard"
  endpoint_type   = "public"
  force_delete    = true
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"

  key     = "index.html"
  content = local.resolved_index_html

  force_delete = true
}

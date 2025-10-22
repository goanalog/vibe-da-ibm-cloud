# Vibe Manifestation Engine v1.4 — JSON Schema Final Edition
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    ibm = { source = "IBM-Cloud/ibm", version = ">= 1.62.0" }
    random = { source = "hashicorp/random", version = ">= 3.0" }
  }
}

provider "ibm" {}

data "ibm_resource_group" "group" { name = "Default" }

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "vibe_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}" [cite: 3]
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = var.region
  force_delete         = true
}

locals {
  html_source = (
    length(trimspace(var.vibe_html_input)) > 0 ?
      var.vibe_html_input : [cite: 4]
      file("${path.module}/index.html")
  )
  html_base64 = base64encode(local.html_source)
}

resource "ibm_cos_object" "vibe_app" {
  bucket         = ibm_cos_bucket.vibe_bucket.bucket_name
  key            = "index.html"
  content_base64 = local.html_base64
  content_type   = "text/html"
}

# Ensure all variables are visible to IBM Catalog
resource "null_resource" "expose_vars" {
  triggers = {
    vibe_html_input = var.vibe_html_input
    region          = var.region
  }
}
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
  numeric = true
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  region_location      = var.region
  resource_instance_id = ibm_resource_instance.cos_instance.id
  storage_class        = "standard"
  force_delete         = true
  endpoint_type        = "public"
}

# ✅ Public access configuration using supported ibm_cos_bucket_config
resource "ibm_cos_bucket_config" "public_access" {
  bucket_crn = ibm_cos_bucket.bucket.crn

  firewall {
    allowed_ip = ["0.0.0.0/0"]
  }

  metrics_monitoring {
    usage_metrics_enabled    = true
    request_metrics_enabled  = true
  }
}

# Upload user-provided HTML or fallback to index.html
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("index.html")
  endpoint_type   = "public"
  force_delete    = true
}

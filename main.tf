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

provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

variable "region" {
  default = "us-south"
}

resource "ibm_resource_instance" "vibe_cos" {
  name     = "vibe-cos-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = var.region
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_cos.id
  storage_class        = "standard"
  force_delete         = true
}

output "vibe_url" {
  description = "Public URL for your deployed Vibe app"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
}

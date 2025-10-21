# ~*~ The Manifestation Ritual ~*~
# This sacred script translates your intentions into digital reality.
# Observe as the cloud bends to your will.

terraform {
  required_version = ">= 1.2.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.84.0" # Channeling a stable frequency
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0" # Invoking cosmic randomness
    }
  }
}

provider "ibm" {
  region = var.region
}

# First, we connect with the target collective (Resource Group).
data "ibm_resource_group" "group" {
  name = var.resource_group
}

# We invoke a unique energetic signature to avoid vibrational collisions.
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  number  = true
  special = false
}

# We conjure the astral home, a global sanctuary for our artifact.
resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_instance_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite" # A humble beginning for a powerful vibe
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
  tags              = ["deployable-architecture", "ibm-cloud", "static-website", "vibe"]
}

# Within this home, we shape the vessel (the bucket) in our chosen region.
resource "ibm_cos_bucket" "bucket" {
  resource_instance_id = ibm_resource_instance.cos_instance.id
  bucket_name          = "${var.bucket_name}-${random_string.suffix.result}"
  region_location      = var.region
  storage_class        = "standard"
  endpoint_type        = "public"
  force_delete         = true # Allowing for swift reincarnation
}

# Finally, we breathe the soul of the app into the vessel.
resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"
  key             = "index.html"
  content         = var.index_html # The HTML essence, made manifest
  force_delete    = true

  depends_on = [ibm_cos_bucket.bucket]
}


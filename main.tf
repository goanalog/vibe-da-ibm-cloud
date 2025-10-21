# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Vibe Deployable Architecture — "Instant Vibe Coder"
# Version: 0.1.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "ibm" {}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.cos_name}-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_plan == "lite" ? "global" : var.region
  resource_group_id = data.ibm_resource_group.group.id

  tags = ["vibe", "vibe-coder", "deployable-architecture", "sample"]
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

provider "ibm" {
  region = var.region
}

variable "region" {
  type        = string
  description = "IBM Cloud region (example: us-south)"
}

variable "resource_group" {
  type        = string
  description = "Name of the IBM Cloud resource group"
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "vibe-instance-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
  force_delete         = true
}

resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  bucket_crn = ibm_cos_bucket.bucket.crn

  website_configuration {
    main_document {
      suffix = "index.html"
    }
    error_document {
      key = "404.html"
    }
  }
}

resource "ibm_function_namespace" "ns" {
  name              = "vibe-ns-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_function_package" "pkg" {
  name      = "vibe-funcs-${random_string.suffix.result}"
  namespace = ibm_function_namespace.ns.name
}

resource "ibm_function_action" "push_to_cos" {
  name      = "push_to_cos"
  namespace = ibm_function_namespace.ns.name

  exec {
    kind      = "nodejs:18"
    code_path = "${path.module}/functions/push_to_cos.zip"
  }
}

resource "ibm_function_action" "push_to_project" {
  name      = "push_to_project"
  namespace = ibm_function_namespace.ns.name

  exec {
    kind      = "nodejs:18"
    code_path = "${path.module}/functions/push_to_project.zip"
  }
}

locals {
  functions_base   = "https://${var.region}.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns.name}/default"
  push_cos_url     = "${local.functions_base}/${ibm_function_action.push_to_cos.name}"
  push_project_url = "${local.functions_base}/${ibm_function_action.push_to_project.name}"
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn   = ibm_cos_bucket.bucket.crn
  key          = "index.html"
  content      = base64encode(
                   replace(
                     replace(
                       file("${path.module}/index.html"),
                       "__PUSH_COS_URL__",
                       local.push_cos_url
                     ),
                     "__PUSH_PROJECT_URL__",
                     local.push_project_url
                   )
                 )
  content_type = "text/html"
}

resource "ibm_cos_bucket_object" "page_404" {
  bucket_crn   = ibm_cos_bucket.bucket.crn
  key          = "404.html"
  content      = base64encode(file("${path.module}/404.html"))
  content_type = "text/html"
}

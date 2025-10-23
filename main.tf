terraform {
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
  upper   = false
  lower   = true
  number  = true
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
  endpoint_type        = "public"
  force_delete         = true
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"
  key             = "index.html"
  content         = file("${path.module}/index.html")
  force_delete    = true
}

resource "ibm_cos_bucket_object" "page_404" {
  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"
  key             = "404.html"
  content         = file("${path.module}/404.html")
  force_delete    = true
}

resource "ibm_cos_bucket_website_configuration" "bucket_website" {
  depends_on = [
    ibm_resource_instance.cos_instance,
    ibm_cos_bucket.bucket,
    ibm_cos_bucket_object.page_404
  ]

  bucket_crn      = ibm_cos_bucket.bucket.crn
  bucket_location = var.region
  endpoint_type   = "public"

  website_configuration {
    index_document {
      suffix = "index.html"
    }
    error_document {
      key = "404.html"
    }
  }
}

resource "null_resource" "wait_for_dns" {
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ibm_function_namespace" "ns" {
  depends_on        = [null_resource.wait_for_dns]
  name              = "vibe-func-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_function_package" "pkg" {
  name      = "vibe-func-${random_string.suffix.result}"
  namespace = ibm_function_namespace.ns.name
  publish   = false
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

output "vibe_bucket" {
  value = ibm_cos_bucket.bucket.bucket_name
}

output "vibe_url" {
  description = "Public website endpoint"
  value       = ibm_cos_bucket_website_configuration.bucket_website.website_endpoint
}

output "vibe_bucket_url" {
  description = "Bucket website endpoint (alias)"
  value       = ibm_cos_bucket_website_configuration.bucket_website.website_endpoint
}

output "push_cos_url" {
  description = "IBM Cloud Function endpoint for pushing to COS"
  value       = ibm_function_action.push_to_cos.target_endpoint_url
}

output "push_project_url" {
  description = "IBM Cloud Function endpoint for pushing to Projects"
  value       = ibm_function_action.push_to_project.target_endpoint_url
}
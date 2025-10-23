terraform {
  required_version = ">= 1.5.0"
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

data "ibm_resource_group" "default" {
  is_default = true
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "ibm_resource_instance" "cos" {
  name              = "vibe-cos-${random_string.suffix.result}"
  service           = "cloud-object-storage"
  plan              = "lite"
  location          = "global"
  resource_group_id = data.ibm_resource_group.default.id
  tags              = ["vibe", "starter"]
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = var.region
  storage_class        = "standard"
}

resource "ibm_cos_bucket_object" "index_html" {
  bucket_crn      = ibm_resource_instance.cos.id
  bucket_name     = ibm_cos_bucket.bucket.bucket_name
  key             = "index.html"
  content         = var.html_input != "" ? var.html_input : file("${path.module}/index.html")
  content_type    = "text/html"
  region_location = var.region
  etag_verify     = false
  depends_on      = [ibm_cos_bucket.bucket]
}

resource "ibm_function_namespace" "ns" {
  name              = "vibe-ns-${random_string.suffix.result}"
  resource_group_id = data.ibm_resource_group.default.id
}

resource "ibm_function_package" "pkg" {
  name        = "vibe-package-${random_string.suffix.result}"
  namespace   = ibm_function_namespace.ns.name
  publish     = true
  description = "Vibe function package"
}

resource "ibm_function_action" "push_to_cos" {
  name        = "${ibm_function_package.pkg.name}/push_to_cos"
  namespace   = ibm_function_namespace.ns.name
  description = "Inline verify endpoint: echoes bytes; Terraform handles initial upload."
  publish     = true
  web         = true

  exec {
    kind = "nodejs:default"
    code = <<-EOF
      async function main(params) {
        const { bucket_name, html_input } = params;
        const size = (html_input || "").length;
        return {
          statusCode: 200,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            ok: true,
            message: "Inline action alive - redeploy with html_input to update COS.",
            bucket: bucket_name,
            received_bytes: size
          })
        };
      }
      exports.main = main;
    EOF
  }

  parameters = {
    bucket_name = ibm_cos_bucket.bucket.bucket_name
    html_input  = var.html_input != "" ? var.html_input : file("${path.module}/index.html")
  }

  limits { timeout = 60000 }
}

output "vibe_url" {
  description = "Open your live site"
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/index.html"
  metadata {
    displayName       = "Open live site"
    primaryoutputlink = true
  }
}

output "vibe_action_url" {
  description = "Test your publish endpoint (inline, dependency-free)."
  value       = "https://us-south.functions.appdomain.cloud/api/v1/web/${ibm_function_namespace.ns.name}/${ibm_function_action.push_to_cos.name}"
}

output "vibe_bucket_url" {
  description = "Bucket root (enable Static website for a pretty root path)."
  value       = "https://s3.${var.region}.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.bucket.bucket_name}/"
}

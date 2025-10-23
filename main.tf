provider "ibm" {}
provider "null" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  html_content = var.vibe_code_raw != "" ? var.vibe_code_raw : file("${path.module}/index.html")
}

resource "ibm_resource_instance" "vibe_instance" {
  name     = "vibe-instance-${random_string.suffix.result}"
  service  = "cloud-object-storage"
  plan     = "lite"
  location = "global"
}

resource "ibm_cos_bucket" "vibe_bucket" {
  bucket_name          = "vibe-bucket-${random_string.suffix.result}"
  resource_instance_id = ibm_resource_instance.vibe_instance.id
  storage_class        = "standard"
  region_location      = "us-south"
  force_delete         = true
}

resource "ibm_cos_bucket_object" "vibe_code" {
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn
  bucket_location = ibm_cos_bucket.vibe_bucket.region_location

  key     = "index.html"
  content = local.html_content
  etag    = md5(local.html_content)
}

# --- THE AWS CLI HACK ---
# This uses the awscli (which should be in the environment)
# to set the public ACL via the S3 API.
resource "null_resource" "make_object_public" {
  depends_on = [ibm_cos_bucket_object.vibe_code]

  provisioner "local-exec" {
    # Command uses awscli s3api to set public-read ACL
    # We use the public S3 endpoint provided by the ibm_cos_bucket resource
    command = "aws --endpoint-url https://${ibm_cos_bucket.vibe_bucket.s3_endpoint_public} s3api put-object-acl --bucket ${ibm_cos_bucket.vibe_bucket.bucket_name} --key ${ibm_cos_bucket_object.vibe_code.key} --acl public-read"
  }
}
# --- END HACK ---

output "vibe_url" {
  value       = "https://s3.us-south.cloud-object-storage.appdomain.cloud/${ibm_cos_bucket.vibe_bucket.bucket_name}/index.html"
  description = "Public URL for your deployed Vibe app"
}
# main.tf

provider "ibm" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  # Use templatefile to inject function URLs into the HTML
  html_content = templatefile("${path.module}/index.html.tftpl", {
    # Get the public URL of our new function
    function_push_url = ibm_function_action.push_to_cos.web_action_url
    
    # This one is still a placeholder, as it's not built yet
    function_request_url = "" 
    
    # Pass through the project URL variable
    project_url = var.project_url
  })
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
  # Use the *rendered* HTML content from the template
  content = local.html_content
  etag    = md5(local.html_content)
}

# This applies an S3-native bucket policy to allow public read access
resource "ibm_cos_bucket_policy" "vibe_bucket_policy" {
  bucket_crn = ibm_cos_bucket.vibe_bucket.crn
  
  policy_document = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${ibm_cos_bucket.vibe_bucket.bucket_name}/*"
      }
    ]
  })
}
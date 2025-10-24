resource "ibm_resource_instance" "cos_instance" { [cite: 2]
  name     = "vibe-instance" [cite: 2]
  service  = "cloud-object-storage" [cite: 2]
  plan     = "lite" [cite: 2]
  location = "global" [cite: 2]
}

resource "random_string" "suffix" { [cite: 2]
  length  = 6 [cite: 2]
  upper   = false [cite: 2]
  special = false [cite: 2]
}

resource "ibm_cos_bucket" "vibe_bucket" { [cite: 2]
  bucket_name          = "${var.bucket_prefix}-${random_string.suffix.result}" [cite: 2]
  resource_instance_id = ibm_resource_instance.cos_instance.id [cite: 2]
  storage_class        = "standard" [cite: 2]
  force_delete         = true [cite: 2]
}

resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" { [cite: 2]
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn 
  bucket_location = var.region 

  website_configuration { 
    index_document { 
      suffix = var.website_index 
    }

    error_document { 
      key = var.website_error 
    }
  }
}

resource "ibm_cos_bucket_object" "index_html" { 
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn 
  bucket_location = var.region 
  key             = var.website_index 
  content         = file("${path.module}/sample-app/index.html") 
}

resource "ibm_cos_bucket_object" "error_html" { 
  bucket_crn      = ibm_cos_bucket.vibe_bucket.crn [cite: 4]
  bucket_location = var.region [cite: 4]
  key             = var.website_error [cite: 4]
  content         = file("${path.module}/sample-app/404.html") [cite: 4]
}
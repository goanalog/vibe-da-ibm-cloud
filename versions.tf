terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # Require a newer provider that supports ibm_cos_bucket_public_access
      version = ">= 1.85.0" 
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    # No longer need the null provider
  }
  # Optional: Enforce the Terraform engine version (will error if Schematics ignores catalog.json)
  # required_version = ">= 1.5.0" 
}
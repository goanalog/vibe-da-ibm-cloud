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
    # Add this provider for zipping files
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}
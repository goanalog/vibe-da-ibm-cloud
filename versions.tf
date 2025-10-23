terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # Keep the version that works for your environment
      version = ">= 1.84.0" 
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
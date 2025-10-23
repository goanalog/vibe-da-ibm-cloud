terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # FIX: Force a provider version newer than 1.84.2
      version = ">= 1.85.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    
}
  }
}
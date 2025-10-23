terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # Go back to the version that works
      version = ">= 1.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    # Add the "null" provider for our workaround
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}
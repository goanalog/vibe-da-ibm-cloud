terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      # Specify the minimum version known to work, or a newer one
      # Example: Require at least version 1.90.0 (check latest compatible 1.x)
      # Or, if you know a specific later version works: version = "~> 1.90"
      # For now, let's keep the original minimum, but ideally, you'd increase this
      # once you confirm the version used in your environment.
      version = ">= 1.84.3" # Or ideally a higher known-good version like ">= 1.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
  # You might also specify required Terraform version here if needed
  # required_version = ">= 1.1.0"
}

provider "ibm" {
  region = var.region
  # No API key needed if using Trusted Profiles
}

# Keep the provider "ibm" block here too for organization
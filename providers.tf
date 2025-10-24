terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # --- IMPORTANT: Provider version ---
      # Supports Code Engine function deployment arguments like
      # code_reference and run_env_variables.
      # Adjust as needed if Schematics upgrades provider versions.
      version = ">= 1.87.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "ibm" {
  region = var.region
  # No API key specified – relies on IBM Cloud Trusted Profile or
  # environment variables automatically set by Schematics/Projects.
}

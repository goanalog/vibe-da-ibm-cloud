terraform {
  required_version = ">= 1.5.0"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      # Provider supports modern features and Schematics fleet
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
  # Relies on IBM Cloud Trusted Profile / env in Projects & Schematics
}

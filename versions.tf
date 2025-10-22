terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~>1.59"
    }
  }

  required_version = ">= 1.4.6"
}
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    ibm = { source = "ibm-cloud/ibm", version = ">= 1.84.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.1" }
  }
}

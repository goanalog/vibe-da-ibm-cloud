terraform {
  required_version = ">= 1.4.0"
  required_providers {
    ibm = { source = "ibm-cloud/ibm", version = ">= 1.84.0" }
    random = { source = "hashicorp/random", version = ">= 3.5.1" }
    local  = { source = "hashicorp/local", version = ">= 2.4.0" }
  }
}
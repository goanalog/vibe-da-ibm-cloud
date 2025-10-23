
variable "region" {
  type        = string
  description = "IBM Cloud region for COS"
  default     = "us-south"
}


# Added for v1.1.5 — declare resource group variable
variable "resource_group" {
  description = "IBM Cloud Resource Group name"
  type        = string
  default     = "default"
}

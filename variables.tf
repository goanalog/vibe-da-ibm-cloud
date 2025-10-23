variable "region" {
  description = "Region for COS bucket and IBM Cloud Functions."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud Resource Group name."
  type        = string
  default     = "default"
}

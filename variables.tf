variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key used to authenticate with IBM Cloud services."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The IBM Cloud region where the resources will be deployed (e.g. us-south, eu-de)."
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  description = "The ID of the IBM Cloud Resource Group in which to create resources."
  type        = string
}

variable "enable_functions" {
  description = "Whether to deploy IBM Cloud Functions for push-to-COS and push-to-Project actions."
  type        = bool
  default     = true
}

# Optional — controls for website or bucket behavior (safe defaults)
variable "website_index" {
  description = "Name of the index file served by the COS website."
  type        = string
  default     = "index.html"
}

variable "website_error" {
  description = "Name of the error file served by the COS website."
  type        = string
  default     = "404.html"
}

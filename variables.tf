
variable "region" {
  description = "IBM Cloud region for bucket deployment (e.g., us-south)"
  type        = string
}

variable "resource_group" {
  description = "Resource group name to deploy the COS instance into"
  type        = string
}

variable "html_input" {
  description = "Custom HTML code for your Vibe app (optional)"
  type        = string
  default     = ""
}

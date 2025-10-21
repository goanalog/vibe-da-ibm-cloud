
variable "region" {
  description = "The IBM Cloud region for deployment."
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "IBM Cloud resource group for deployment."
  type        = string
  default     = "Default"
}

variable "cos_plan" {
  description = "Choose your Cloud Object Storage plan (lite or standard)."
  type        = string
  default     = "lite"
}

variable "index_html" {
  description = "Paste your vibe-coded HTML here. Leave blank to use the included index.html sample app."
  type        = string
  default     = ""
}

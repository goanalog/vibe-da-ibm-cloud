variable "resource_group" {
  description = "IBM Cloud Resource Group where your vibe lives."
  type        = string
  default     = "default"
}

variable "region" {
  description = "IBM Cloud region (e.g., us-south)."
  type        = string
  default     = "us-south"
}

variable "cos_instance_name" {
  description = "Friendly name for your IBM Cloud Object Storage instance."
  type        = string
  default     = "vibe-coder-cos"
}

variable "bucket_name" {
  description = "Base name for your COS bucket (lowercase, no spaces)."
  type        = string
  default     = "vibe-coder-sample-bucket"
}

variable "index_html" {
  description = "Inline HTML code pasted by the user."
  type        = string
  default     = ""
}

variable "index_html_file" {
  description = "Optional local path to an index.html file, used if inline HTML is not provided."
  type        = string
  default     = ""
}

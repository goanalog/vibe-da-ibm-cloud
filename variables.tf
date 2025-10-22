variable "vibe_html_input" {
  description = "Paste your HTML code here (if left blank, a default sample app will be deployed)."
  type        = string
  default     = ""
}

variable "region" {
  description = "IBM Cloud region for the COS instance."
  type        = string
  default     = "us-south"
}

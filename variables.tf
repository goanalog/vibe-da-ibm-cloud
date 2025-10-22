variable "vibe_html_input" {
  description = "Paste your HTML code here (if left blank, a default sample app will be deployed)." [cite: 6]
  type        = string [cite: 7]
  default     = ""
}

variable "region" {
  description = "IBM Cloud region for the COS instance."
  type        = string [cite: 9]
  default     = "us-south"
}
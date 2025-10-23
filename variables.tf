
variable "region" {
  type        = string
  description = "IBM Cloud region for the bucket and endpoints"
  default     = "us-south"
}

variable "html_input" {
  type        = string
  description = "Optional inline HTML to publish as index.html (falls back to bundled file)"
  default     = ""
}

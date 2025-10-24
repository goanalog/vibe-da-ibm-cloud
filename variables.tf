variable "region" {
  description = "IBM Cloud region (e.g., us-south)"
  type        = string
  default     = "us-south"
}

variable "bucket_prefix" {
  description = "Prefix for the COS bucket"
  type        = string
  default     = "vibe-bucket"
}

variable "website_index" {
  description = "Index file for website hosting"
  type        = string
  default     = "index.html"
}

variable "website_error" {
  description = "Error file for website hosting"
  type        = string
  default     = "404.html"
}
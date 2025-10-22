variable "region" {
  type        = string
  default     = "us-south"
  description = "IBM Cloud region (default us-south)."
}

variable "bucket_prefix" {
  type        = string
  default     = "vibe-bucket"
  description = "Prefix for the bucket name (a 6-char suffix is added)."
}

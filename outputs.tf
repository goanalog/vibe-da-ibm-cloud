output "vibe_bucket_crn" {
  value = ibm_cos_bucket.bucket.crn
}

output "push_cos_url" {
  value = local.push_cos_url
}

output "push_project_url" {
  value = local.push_project_url
}

variable "region" { description="IBM Cloud region (e.g., us-south)"; type=string; default="us-south" }
variable "resource_group_name" { description="Resource group"; type=string; default="Default" }
variable "bucket_name" { description="Optional bucket name"; type=string; default=null }
variable "enable_functions" { description="Enable Functions"; type=bool; default=true }

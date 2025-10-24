 2025/10/24 04:34:25 [1m-----  New Workspace Action  -----[21m[0m
 2025/10/24 04:34:25 Request: activitId=94e211bc5b5b073dbbe337a9ec8ae343, account=86f643a12a9841529056e2703838ccb4, owner=realbrendan@us.ibm.com, requestID=96acc4ae-2c4e-41f8-b94d-9821674b368e
 2025/10/24 04:34:25 Related Activity: action=TERRAFORM_COMMANDS, workspaceID=us-south.workspace.globalcatalog-collection.228ad542, processedBy=orchestrator-5f687b4cbc-gzmsk
 2025/10/24 04:34:25 Related Workspace: name=vibe-da-ibm-cloud-skittles-10-24-2025, sourcerelease=(not specified), sourceurl=, folder=vibe-da-ibm-cloud-skittles
 2025/10/24 04:34:28  --- Ready to execute the command --- 
 2025/10/24 04:34:32 workspace.template.EnvFile: 8ee959f7-6304-4d46-a3f9-36bb388668f4
 2025/10/24 04:34:33 workspace.template.SecFile: c72cc80e-47c2-494e-a039-3421b54bc086
 2025/10/24 04:34:31 [1m-----  New Action  -----[21m[0m
 2025/10/24 04:34:31 Request: requestID=96acc4ae-2c4e-41f8-b94d-9821674b368e
 2025/10/24 04:34:34 Related Activity: action=TF_COMMAND, workspaceID=us-south.workspace.globalcatalog-collection.228ad542, processedByOrchestrator=96acc4ae-2c4e-41f8-b94d-9821674b368e_94e211bc5b5b073dbbe337a9ec8ae343, processedByJob=job12-7bd7dddb5c-pw7tv, actionType=Terraform
 
 2025/10/24 04:34:39 [1m-----  Terraform INIT  -----[21m[0m
 
 2025/10/24 04:34:39 [34mStarting command: terraform1.12 init -input=false -no-color[39m[0m
 2025/10/24 04:34:39 Starting command: terraform1.12 init -input=false -no-color
 2025/10/24 04:34:39 Terraform init | Initializing the backend...
 2025/10/24 04:34:39 Terraform init | Initializing provider plugins...
 2025/10/24 04:34:39 Terraform init | - Finding hashicorp/random versions matching ">= 3.0.0"...
 2025/10/24 04:34:40 Terraform init | - Finding ibm-cloud/ibm versions matching ">= 1.84.0"...
 2025/10/24 04:34:40 Terraform init | - Installing hashicorp/random v3.7.2...
 2025/10/24 04:34:41 Terraform init | - Installed hashicorp/random v3.7.2 (signed by HashiCorp)
 2025/10/24 04:34:41 Terraform init | - Installing ibm-cloud/ibm v1.84.3...
 2025/10/24 04:34:44 Terraform init | - Installed ibm-cloud/ibm v1.84.3 (self-signed, key ID AAD3B791C49CC253)
 2025/10/24 04:34:44 Terraform init | Partner and community providers are signed by their developers.
 2025/10/24 04:34:44 Terraform init | If you'd like to know more about provider signing, you can read about it here:
 2025/10/24 04:34:44 Terraform init | https://developer.hashicorp.com/terraform/cli/plugins/signing
 2025/10/24 04:34:44 Terraform init | Terraform has created a lock file .terraform.lock.hcl to record the provider
 2025/10/24 04:34:44 Terraform init | selections it made above. Include this file in your version control repository
 2025/10/24 04:34:44 Terraform init | so that Terraform can guarantee to make the same selections by default when
 2025/10/24 04:34:44 Terraform init | you run "terraform init" in the future.
 2025/10/24 04:34:44 Terraform init | 
 2025/10/24 04:34:44 Terraform init | Terraform has been successfully initialized!
 2025/10/24 04:34:44 Command finished successfully.
 
 2025/10/24 04:34:44 [1m-----  Terraform Commands  -----[21m[0m
 
 2025/10/24 04:34:44 [34mStarting command: terraform1.12 plan -input=false -refresh=true -state=terraform.tfstate -var-file=schematics.tfvars -no-color -out=tfplan.binary[39m[0m
 2025/10/24 04:34:44 Starting command: terraform1.12 plan -input=false -refresh=true -state=terraform.tfstate -var-file=schematics.tfvars -no-color -out=tfplan.binary
 2025/10/24 04:34:45 Terraform plan | 
 2025/10/24 04:34:45 Terraform plan | Warning: Deprecated flag: -state
 2025/10/24 04:34:45 Terraform plan | 
 2025/10/24 04:34:45 Terraform plan | Use the "path" attribute within the "local" backend to specify a file for
 2025/10/24 04:34:45 Terraform plan | state storage
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Missing required argument
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 21, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:47 Terraform plan |   21: resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | The argument "bucket_location" is required, but no definition was found.
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Insufficient website_configuration blocks
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 21, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:47 Terraform plan |   21: resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | At least 1 "website_configuration" blocks are required.
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Unsupported argument
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 23, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:47 Terraform plan |   23:   index_document = var.website_index
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | An argument named "index_document" is not expected here.
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Unsupported argument
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 24, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:47 Terraform plan |   24:   error_document = var.website_error
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | An argument named "error_document" is not expected here.
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Invalid resource type
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 27, in resource "ibm_cos_object" "index_html":
 2025/10/24 04:34:47 Terraform plan |   27: resource "ibm_cos_object" "index_html" {
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | The provider ibm-cloud/ibm does not support resource type "ibm_cos_object".
 2025/10/24 04:34:47 Terraform plan | Did you mean "ibm_cm_object"?
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | Error: Invalid resource type
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan |   on main.tf line 34, in resource "ibm_cos_object" "error_html":
 2025/10/24 04:34:47 Terraform plan |   34: resource "ibm_cos_object" "error_html" {
 2025/10/24 04:34:47 Terraform plan | 
 2025/10/24 04:34:47 Terraform plan | The provider ibm-cloud/ibm does not support resource type "ibm_cos_object".
 2025/10/24 04:34:47 Terraform plan | Did you mean "ibm_cm_object"?
 2025/10/24 04:34:47 [1m[31mTerraform PLAN error: Terraform PLAN errorexit status 1[39m[0m
 
 2025/10/24 04:34:47 [1m-----  Terraform PLAN  -----[21m[0m
 
 2025/10/24 04:34:47 [34mStarting command: terraform1.12 plan -input=false -refresh=true -state=terraform.tfstate -var-file=schematics.tfvars -no-color -out=tfplan.binary[39m[0m
 2025/10/24 04:34:47 Starting command: terraform1.12 plan -input=false -refresh=true -state=terraform.tfstate -var-file=schematics.tfvars -no-color -out=tfplan.binary
 2025/10/24 04:34:48 Terraform plan | 
 2025/10/24 04:34:48 Terraform plan | Warning: Deprecated flag: -state
 2025/10/24 04:34:48 Terraform plan | 
 2025/10/24 04:34:48 Terraform plan | Use the "path" attribute within the "local" backend to specify a file for
 2025/10/24 04:34:48 Terraform plan | state storage
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Missing required argument
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 21, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:51 Terraform plan |   21: resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | The argument "bucket_location" is required, but no definition was found.
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Insufficient website_configuration blocks
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 21, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:51 Terraform plan |   21: resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website" {
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | At least 1 "website_configuration" blocks are required.
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Unsupported argument
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 23, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:51 Terraform plan |   23:   index_document = var.website_index
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | An argument named "index_document" is not expected here.
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Unsupported argument
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 24, in resource "ibm_cos_bucket_website_configuration" "vibe_bucket_website":
 2025/10/24 04:34:51 Terraform plan |   24:   error_document = var.website_error
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | An argument named "error_document" is not expected here.
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Invalid resource type
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 27, in resource "ibm_cos_object" "index_html":
 2025/10/24 04:34:51 Terraform plan |   27: resource "ibm_cos_object" "index_html" {
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | The provider ibm-cloud/ibm does not support resource type "ibm_cos_object".
 2025/10/24 04:34:51 Terraform plan | Did you mean "ibm_cm_object"?
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | Error: Invalid resource type
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan |   on main.tf line 34, in resource "ibm_cos_object" "error_html":
 2025/10/24 04:34:51 Terraform plan |   34: resource "ibm_cos_object" "error_html" {
 2025/10/24 04:34:51 Terraform plan | 
 2025/10/24 04:34:51 Terraform plan | The provider ibm-cloud/ibm does not support resource type "ibm_cos_object".
 2025/10/24 04:34:51 Terraform plan | Did you mean "ibm_cm_object"?
 2025/10/24 04:34:51 [1m[31mTerraform PLAN error: Terraform PLAN errorexit status 1[39m[0m
 2025/10/24 04:34:51 [1m[31mCould not execute job: Error : Terraform PLAN errorexit status 1[39m[0m
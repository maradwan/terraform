locals {

  remote_state_bucket = "terraform-state-${local.account_vars["gcp_account_id"]}"
  remote_state_key    = "${path_relative_to_include()}/${replace(path_relative_to_include(), "/", "_")}"

  account_vars_file = find_in_parent_folders("account.yaml")
  account_vars   = yamldecode(fileexists(local.account_vars_file) ? file(local.account_vars_file) : "{}")

  global_vars_file = find_in_parent_folders("global.yaml")
  global_vars      = yamldecode(fileexists(local.global_vars_file) ? file(local.global_vars_file) : "{}")

  environment_vars_file = find_in_parent_folders("environment.yaml", "ignore")
  environment_vars =  yamldecode(fileexists(local.environment_vars_file) ? file(local.environment_vars_file) : "{}")

  region_vars_file = find_in_parent_folders("region.yaml", "ignore")
  region_vars = yamldecode(fileexists(local.region_vars_file) ? file(local.region_vars_file) : "{}")

  platform_vars_file = find_in_parent_folders("platform.yaml", "ignore")
  platform_vars = yamldecode(fileexists(local.platform_vars_file) ? file(local.platform_vars_file) : "{}")

  gcp_region   = local.region_vars.region


 merged_inputs = merge(
 local.global_vars,
 local.account_vars,
 local.environment_vars,
 local.region_vars,
 local.platform_vars,
 )

 all_inputs = merge(
 local.merged_inputs,
 {

  project = "${local.account_vars["gcp_account_id"]}"
  region = local.region_vars.region

},
 
 )

}
inputs = local.all_inputs


remote_state {
 backend = "gcs" 
 config = {
   bucket = local.remote_state_bucket
   prefix = local.remote_state_key

   project = "${local.account_vars["gcp_account_id"]}"
   location = local.global_vars["tf_state_region"]
 }
  generate = {
    path   = "tf-backend.tf"
    if_exists = "overwrite_terragrunt" 
  }
}

generate "provider" {
  path = "provider.tf"

  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "google" {
    project = "${local.account_vars["gcp_account_id"]}"
   region = "${local.gcp_region}"  
}
terraform {
   required_providers {
    google = "4.10.0"
  }  
}

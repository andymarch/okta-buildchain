variable "org_name" {}
variable "api_token" {}
variable "base_url" {}

data "okta_group" "all" {
  name = "Everyone"
}

provider "okta" { 
    org_name = var.org_name
    base_url = var.base_url
    api_token = var.api_token
}

//extension to schema must be created one at a time, use depends_on to order the
//creation of schema extensions

resource "okta_user_schema" "dob_extension" {
  index  = "date_of_birth"
  title  = "Date of Birth"
  type   = "string"
  master = "PROFILE_MASTER"
  required = true  
}
resource "okta_user_schema" "crn_extension" {
  index  = "customer_reference_number"
  title  = "Customer Reference Number"
  required = true
  type   = "string"
  master = "PROFILE_MASTER"
  depends_on = [okta_user_schema.dob_extension]
}

resource "okta_auth_server" "demonstration_service" {
   audiences = ["demo.local"]
   description = "Authorization service as code."
   name = "Demonstration Service"
} 

resource "okta_auth_server_scope" "demonstration_perfrom" { 
   description = "Perform a demonstration"
   name = "demonstration:perform"
   auth_server_id = okta_auth_server.demonstration_service.id
}

resource "okta_auth_server_scope" "demonstration_complete" { 
   description = "Complete a demonstration"
   name = "demonstration:complete"
   auth_server_id = okta_auth_server.demonstration_service.id
}
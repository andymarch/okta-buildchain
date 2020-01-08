# Managing Multiple Okta Instances with Terraform

Congratulations you've chosen to use Okta to solve your identity problems,
welcome to the happy sunny utopia of a managed identity solution! But wait your
developers want to add new features, your testers want a known state to run
their tests against and you need to make sure your service is stable for your
customers; you need more instances! But now you're managing state! Is QA really
like production? What changes did the developers make to their configuration to
get that new feature to work! You need change control! In this article we'll see
how you can solve both problems at once by defining your Okta configuration as
code.

## What is configuration as code

Defining application configuration as code is not new, but automating it is. You
have many options when it comes to picking a 

## Terraform

Instead of using the Okta Admin UI, you define your Okta infrastructure in 
Terraform configuration files using the HashiCorp Configuration Language (HCL). 
HCL is a declarative language that operators use to define the desired
resources. Terraform then makes the necessary API calls to Okta to build the 
requested state, enabling you to automate the provisioning and deployment 
processes of your Okta org. 

## Getting started

Let's create a simple Terraform script to update Okta's user user schema.

### Creating an org

### Automating your org

Create a directory called "identity-as-code"
Move inside and run the command "Terraform init". This initializes the state
terraform state file in your directory which tracks what has been applied
remotely.

Create a file call okta.auto.tfvars, this will provide your the variables to 
terraform. 

```
org_name  = "<your-org>"
base_url  = "okta.com"
api_token = "<your-api-token>"
```

The value for your-org is the subdomain of your org if the address of your Okta
instance is dev12345.okta.com your org_name is dev12345. The base_url is
everything after that so be sure to update this if you are using a okta-emea or
okta-preview org.

The api-token you will need to generate. In Okta an API token gives anyone
bearing it the same rights as its creator. In your Okta administration console
select Security from the top navigation and API, then select the tab for Tokens.
[comment]: <> (using the classic UI instructions here)

Create a new file called identity.tf and add the following:

```
variable "org_name" {}
variable "api_token" {}
variable "base_url" {}

provider "okta" { 
    org_name = var.org_name
    base_url = var.base_url
    api_token = var.api_token
}
```

Here we are including the Okta extension for Terraform and providing three
variables to configure it.

Add the following to identity.tf:

```
resource "okta_user_schema" "dob_extension" {
  index  = "date_of_birth"
  title  = "Date of Birth"
  type   = "string"
  master = "PROFILE_MASTER"
  required = true  
}
```

This extends our Okta user schema with a required field which we will use the
store our users date of birth

## Hosted Terraform

Working on your local machine is great when you are working on a project alone
but if your project is complicated enough to need multiple environments being
the only one who can apply changes is restrictive. To solve this let's host the
state of our Terraform in the cloud too.

Hashicorp offer their Terraform Cloud solution allowing you to control access to
different environments (called workspaces)

## Multiple environments

Now we have our configuration working in a single environment we want to add a
second environment so our developers can keep working without impacting
production.

Create a new branch in your version control called "dev".

In Terraform Cloud create a new workspace to represent this new environment.
Target the same repository as before but set the branch specifier to "dev".

This time you will be setting the variables to a different instance of Okta.
Create a second instance of Okta and generate a API token as you did before.

For this environment we're also going to set the apply method in terraform to
auto, this means that if the plan stage is successful the changes will be
immediately applied to the environment.

Run plan and apply again.
[comment]: <> (screenshot apply success)

Your production configuration from the first tenant has now been replicated into
the second.

# Promoting changes

Now our development team wants to make a change to how the service is
configured, we want them to be able to do this but we still want control over
the changes to production.

Here we're going to user GitHub's branch protection rules feature to ensure that any
changes are reviewed before they are applied.

Click "Add Rule" and enter "master" as the branch name pattern to protect you
can then combine the rules you wish to use to protect the production
configuration. Here we're going to apply "Require pull request reviews before
merging" and "Require status checks to pass before merging". With these two
flags we can make sure that one of the owners reviews before the merge is
performed and that the dev environment is in a good state.

Let's try our change process; on your dev branch add the following change to identity.tf:

```
resource "okta_user_schema" "crn_extension" {
  index  = "customer_reference_number"
  title  = "Customer Reference Number"
  required = true
  type   = "string"
  master = "PROFILE_MASTER"
  depends_on = [okta_user_schema.dob_extension]
}
```

Save and push these changes to your remote.

Terraform will trigger run plan (and apply if it is successful) for the dev
environment.

If you log into your development Okta instance you should now be able to select
the profile editor and see both your schema extensions have been applied.

To promote this change to our production environment we'll create a pull
request, this provides an opportunity for the changes to be reviewed by system
owners and for any discussion to take place before the production configuration
is changed.

Once we have created our pull request GitHub gives us a nice UI experiance that
shows our branch protection in action. The status checks that our dev instance
is successful and we wait for a reviewer to confirm the change.

Once our reviewer has approved the change, Terraform automatically runs plan,
again our reviewers have chance to see what impact this will have on the
configuration and accept or reject the change.

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set = "ALL"
}

# Parent OU directly under the org root.
module "ou_workloads" {
  source = "../.."

  name      = "Workloads"
  parent_id = module.org.root_id

  tags = {
    Environment = "shared"
    Owner       = "platform-team"
  }
}

# Child OU under "Workloads". Passing the parent module's `id` output as the
# child module's `parent_id` input is how callers compose an OU tree at the
# root level — the building block stays single-resource.
module "ou_production" {
  source = "../.."

  name      = "Production"
  parent_id = module.ou_workloads.id

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

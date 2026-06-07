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

module "ou_workloads" {
  source = "../.."

  name      = "Workloads"
  parent_id = module.org.root_id
}

locals {
  // Here you can define module metadata
  definitions = {
    tags = {
      ManagedBy             = "Terraform"
      "wanted-cloud:module" = "terraform-aws-organization-unit"
      "wanted-cloud:tier"   = "T1.04"
    }
    validator_expressions = {
      // AWS Organizations Organizational Unit resource
      // AWS API allows any ASCII char (Pattern: [\s\S]*) up to 128 chars; this
      // module ships a stricter, safe-by-default charset (alphanumerics, space,
      // and `._:/=+-@`) to discourage exotic names that complicate scripting and
      // identity-mapping. Override via var.metadata.validator_expressions if you
      // need broader characters.
      aws_organizations_organizational_unit_name      = "^[A-Za-z0-9 ._:/=+\\-@]{1,128}$"
      aws_organizations_organizational_unit_parent_id = "^(r-[a-z0-9]{4,32}|ou-[a-z0-9]{4,32}-[a-z0-9]{8,32})$"
    }
    validator_error_messages = {
      // AWS Organizations Organizational Unit resource
      aws_organizations_organizational_unit_name      = "ou.name must be 1-128 characters and contain only alphanumerics, spaces, and the punctuation set `._:/=+-@`."
      aws_organizations_organizational_unit_parent_id = "ou.parent_id must be a root id (r-xxxx) or a parent OU id (ou-xxxx-yyyyyyyy)."
    }
  }
}

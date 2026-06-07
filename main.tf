/*
 * # wanted-cloud/terraform-aws-organization-unit
 *
 * Terraform building block managing a single AWS Organizations organizational unit.
 */

resource "aws_organizations_organizational_unit" "this" {
  name      = var.name
  parent_id = var.parent_id

  tags = merge(local.metadata.tags, var.tags)

  # NOTE: `aws_organizations_organizational_unit` does not expose a `timeouts {}`
  # block in the AWS provider schema (v5.x) — verified via
  # `terraform providers schema -json`. Resource-type-keyed timeout overrides
  # remain surfaced through var.metadata.resource_timeouts for cross-module
  # consistency but cannot be wired on this resource.
}

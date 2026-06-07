output "id" {
  description = "AWS Organizations OU id (format: `ou-xxxx-yyyyyyyy`). Use as the `parent_id` input of a child OU module instance or as the `parent_id` of a `terraform-aws-organization-account` module instance."
  value       = aws_organizations_organizational_unit.this.id
}

output "arn" {
  description = "ARN of the OU (format: `arn:aws:organizations::<management-account-id>:ou/o-<org-id>/ou-xxxx-yyyyyyyy`)."
  value       = aws_organizations_organizational_unit.this.arn
}

output "name" {
  description = "Friendly OU name — pass-through from var.name."
  value       = aws_organizations_organizational_unit.this.name
}

output "accounts" {
  description = "List of accounts that are direct children of this OU. Each entry exposes `id`, `arn`, `name`, and `email`. Computed at refresh time — empty list immediately after creation since no accounts have been moved into the OU yet."
  value       = aws_organizations_organizational_unit.this.accounts
}

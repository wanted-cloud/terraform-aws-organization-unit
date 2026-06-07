variable "name" {
  description = "Friendly name of the organizational unit shown in the AWS console and Organizations API. 1-128 characters; AWS accepts any ASCII character but this module ships a conservative charset (alphanumerics, spaces, and `._:/=+-@`). Override via var.metadata.validator_expressions if you need broader characters. Name uniqueness is enforced by AWS per-parent — sibling OUs cannot share a name."
  type        = string

  validation {
    condition     = can(regex(local.metadata.validator_expressions["aws_organizations_organizational_unit_name"], var.name))
    error_message = local.metadata.validator_error_messages["aws_organizations_organizational_unit_name"]
  }
}

variable "parent_id" {
  description = "Identifier of the parent under which this OU is created. Accepts either a root id (`r-xxxx`) or a parent OU id (`ou-xxxx-yyyyyyyy`). Changing this value forces replacement (destroying the OU and orphaning any child OUs/accounts) — see Gotchas."
  type        = string

  validation {
    condition     = can(regex(local.metadata.validator_expressions["aws_organizations_organizational_unit_parent_id"], var.parent_id))
    error_message = local.metadata.validator_error_messages["aws_organizations_organizational_unit_parent_id"]
  }
}

variable "tags" {
  description = "Tags applied to the OU resource. Merged with module-level wanted-cloud:* tags (lower precedence) — caller tags win on key conflict."
  type        = map(string)
  default     = {}
}

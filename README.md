<!-- BEGIN_TF_DOCS -->
# wanted-cloud/terraform-aws-organization-unit

Terraform building block managing a single AWS Organizations organizational unit.

## Table of contents

- [Requirements](#requirements)
- [Providers](#providers)
- [Variables](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)
- [Usage](#usage)
- [Importing existing resources](#importing-existing-resources)
- [Gotchas](#gotchas)
- [Contributing](#contributing)

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (5.100.0)

## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: Friendly name of the organizational unit shown in the AWS console and Organizations API. 1-128 characters; AWS accepts any ASCII character but this module ships a conservative charset (alphanumerics, spaces, and `._:/=+-@`). Override via var.metadata.validator\_expressions if you need broader characters. Name uniqueness is enforced by AWS per-parent — sibling OUs cannot share a name.

Type: `string`

### <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id)

Description: Identifier of the parent under which this OU is created. Accepts either a root id (`r-xxxx`) or a parent OU id (`ou-xxxx-yyyyyyyy`). Changing this value forces replacement (destroying the OU and orphaning any child OUs/accounts) — see Gotchas.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_metadata"></a> [metadata](#input\_metadata)

Description: Metadata definitions for the module, this is optional construct allowing override of the module defaults defintions of validation expressions, error messages, resource timeouts and default tags.

Type:

```hcl
object({
    resource_timeouts = optional(
      map(
        object({
          create = optional(string, "30m")
          read   = optional(string, "5m")
          update = optional(string, "30m")
          delete = optional(string, "30m")
        })
      ), {}
    )
    tags                     = optional(map(string), {})
    validator_error_messages = optional(map(string), {})
    validator_expressions    = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags applied to the OU resource. Merged with module-level wanted-cloud:* tags (lower precedence) — caller tags win on key conflict.

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_accounts"></a> [accounts](#output\_accounts)

Description: List of accounts that are direct children of this OU. Each entry exposes `id`, `arn`, `name`, and `email`. Computed at refresh time — empty list immediately after creation since no accounts have been moved into the OU yet.

### <a name="output_arn"></a> [arn](#output\_arn)

Description: ARN of the OU (format: `arn:aws:organizations::<management-account-id>:ou/o-<org-id>/ou-xxxx-yyyyyyyy`).

### <a name="output_id"></a> [id](#output\_id)

Description: AWS Organizations OU id (format: `ou-xxxx-yyyyyyyy`). Use as the `parent_id` input of a child OU module instance or as the `parent_id` of a `terraform-aws-organization-account` module instance.

### <a name="output_name"></a> [name](#output\_name)

Description: Friendly OU name — pass-through from var.name.

## Resources

The following resources are used by this module:

- [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) (resource)

## Usage

> For more detailed examples navigate to `examples` folder of this repository.

Module was also published via Terraform Registry and can be used as a module from the registry.

```hcl
module "ou_workloads" {
  source  = "wanted-cloud/organization-unit/aws"
  version = "~> 0.1"

  name      = "Workloads"
  parent_id = "r-xxxx"
}
```

This module is intentionally a **single-resource building block** — one OU per
module instance. The N-to-1 mapping (declaring an OU tree) lives at the root /
composition layer: callers `for_each` the module or stamp explicit named
instances and wire each child's `parent_id` from a parent's `id` output. The
building block stays pure, so dependency inversion is preserved.

### Minimal — one OU under the org root

```hcl
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
```

### Nested — three-level tree via output-to-input wiring

```hcl
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
```

## Importing existing resources

When an OU already exists in the Organization (it predates Terraform management, or was created via Control Tower / console), import it before the first `terraform apply`:

```bash
terraform import 'module.ou_workloads.aws_organizations_organizational_unit.this' ou-aaaa-bbbbbbbb
```

The OU id (`ou-xxxx-yyyyyyyy`) is the import key. After import, run `terraform plan` and reconcile any drift on `name`, `parent_id`, and `tags`. If the existing OU sits under a different parent than your code declares, fix the code (or move the OU manually) — a `parent_id` mismatch will trigger a destroy-and-recreate, which orphans every child.

## Gotchas

Read these before applying in any organization that matters.

| # | Gotcha | Mitigation |
|---|---|---|
| 1 | **Out-of-band OU rename is detected on the next plan** — someone renames in the console, Terraform proposes to rename it back. | Establish a convention that OU names are owned by code; treat console renames as drift and reconcile in HCL. |
| 2 | **Deleting an OU that still contains child accounts or child OUs fails** with `OrganizationalUnitNotEmptyException`. | Move accounts out (via `terraform-aws-organization-account` `parent_id` update) and destroy child OU modules first. Terraform's dependency graph orders module-owned children correctly; out-of-band children block destroy. |
| 3 | **Changing `parent_id` forces replacement** — the provider marks the field ForceNew. Replacement destroys the OU, which fails if it has children and, even when empty, generates a brand-new OU id that breaks every downstream `parent_id` reference. | Treat `parent_id` as immutable in practice. If you must reparent, move all children to a sibling OU first, then `terraform state mv` the OU resource or import the new id, rather than letting Terraform destroy. |
| 4 | **Maximum nesting depth is 5 levels under the root** (AWS service limit). Attempting to create a 6th-level OU returns `ConstraintViolationException`. | Validate the OU tree depth at the composition layer; the building block has no visibility into the full tree. Flatten taxonomies that need more than 5 levels. |
| 5 | **Name uniqueness is enforced per-parent** — two sibling OUs under the same parent cannot share a name. The error surfaces at apply (`DuplicateOrganizationalUnitException`), not at plan. | Use distinct names per parent; if you must reuse a name (e.g. `Production` under both `Workloads` and `Sandbox`), that is fine since the parents differ. |
| 6 | **The `accounts` output is empty immediately after create** and only populates after a refresh once accounts have been moved into the OU. | Do not chain plan-time decisions on `module.ou.accounts`; treat it as a runtime/read-only convenience. |
| 7 | **OU tags do not propagate to child accounts or to attached policies** — AWS Organizations tags are scoped to the OU resource only. | Use SCP/Tag policies (T1.03 `terraform-aws-organization-policy`) to enforce tagging on child accounts; do not assume OU tags cascade. |
| 8 | **Moving an OU to a new parent is not supported by the AWS Organizations API** — there is no `MoveOrganizationalUnit` call (unlike `MoveAccount`). The only way to "move" an OU is destroy + recreate. | Design the OU hierarchy up front; treat reorganization as a migration project, not a config change. |

## Contributing

_Contributions are welcomed and must follow [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report security issue please follow [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).
---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
<!-- END_TF_DOCS -->

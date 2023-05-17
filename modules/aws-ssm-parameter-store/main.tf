locals {
  parameter_write = module.this.enabled ? { for e in var.parameter_write : e.name => merge(var.parameter_write_defaults, e) } : {}
}

data "aws_ssm_parameter" "read" {
  count = module.this.enabled ? length(var.parameter_read) : 0
  name  = element(var.parameter_read, count.index)
}

resource "aws_ssm_parameter" "default" {
  for_each = local.parameter_write
  # To dynamically add namespace and stage prefix to SSM Parameter Store secrets.
  name = join("", ["/", join("/", [module.this.namespace, module.this.stage, module.this.name, each.key])])

  description     = each.value.description
  type            = each.value.type
  tier            = each.value.tier
  key_id          = each.value.type == "SecureString" && length(var.kms_arn) > 0 ? var.kms_arn : ""
  value           = each.value.value
  overwrite       = each.value.overwrite
  allowed_pattern = each.value.allowed_pattern
  tags            = var.tags

}

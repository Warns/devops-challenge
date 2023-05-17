locals {
  enabled = module.this.enabled ? 1 : 0
}

data "aws_region" "default" {}

data "template_file" "zone_name" {
  count    = local.enabled
  template = replace(var.zone_name, "$$", "$")

  vars = {
    namespace   = module.this.namespace
    environment = module.this.environment
    name        = module.this.name
    stage       = module.this.stage
    id          = module.this.id
    attributes  = join(module.this.delimiter, module.this.attributes)
  }
}

resource "aws_route53_zone" "default" {
  count = local.enabled
  name  = join("", data.template_file.zone_name.*.rendered)
  tags  = module.this.tags
}

resource "aws_route53_record" "soa" {
  count           = local.enabled
  allow_overwrite = true
  zone_id         = join("", aws_route53_zone.default.*.id)
  name            = join("", aws_route53_zone.default.*.name)
  type            = "SOA"
  ttl             = "30"

  records = [
    format("%s. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400", aws_route53_zone.default[0].name_servers[0])
  ]
}

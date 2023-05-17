#module "bootstrap_zone" {
#  source = "./modules/bootstrap-cluster-zone"
#
#  zone_name = join(".", [module.this.namespace, var.top_level_domain])
#
#  context = module.this.context
#
#}
#
#data "aws_route53_zone" "bootstrap_parent_zone" {
#  count        = var.cross_account_parent_zone_enabled ? 1 : 0
#  name         = var.top_level_domain
#  private_zone = false
#}
#
#resource "aws_route53_record" "ns" {
#  count   = var.cross_account_parent_zone_enabled ? 1 : 0
#  zone_id = join("", data.aws_route53_zone.bootstrap_parent_zone.*.zone_id)
#  name    = module.bootstrap_zone.zone_name
#  type    = "NS"
#  ttl     = "60"
#
#  records = module.bootstrap_zone.zone_name_servers
#}

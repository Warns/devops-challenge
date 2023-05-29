module "faceit_sub_zone" {
  source = "./modules/aws-route53-cluster-zone"

  parent_zone_name = data.aws_route53_zone.faceit_parent_zone.name
  zone_name                  = join(".", [module.this.stage, module.faceit_sub_zone.parent_zone_name])
  parent_zone_record_enabled = true

  context = module.this.context
}

module "faceit_private_zone" {
  source = "./modules/aws-route53-cluster-zone"

  zone_name                  = join(".", [module.this.stage, module.this.namespace, "private"])
  private_zone_enabled       = true
  parent_zone_name           = "private"
  parent_zone_record_enabled = false
  vpc_id                     = module.faceit_vpc.vpc_id

  context = module.this.context
}

module "faceit_vpc" {
  source = "./modules/aws-vpc"

  cidr_block = var.vpc_cidr_block

  context = module.this.context
}

module "faceit_vpc_flow_logs" {
  source = "./modules/aws-vpc-flow-logs-s3-bucket"

  enabled          = var.ENABLE_VPC_FLOW_LOGS
  name             = var.vpc_flow_logs_name
  flow_log_enabled = var.flow_log_enabled
  force_destroy    = var.force_destroy
  traffic_type     = var.flow_logs_traffic_type
  vpc_id           = module.faceit_vpc.vpc_id

  context = module.this.context
}

resource "aws_ecs_cluster" "faceit_cluster" {
  name = module.this.id
  tags = module.this.tags
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

module "faceit_ssm_kms_key" {
  source = "./modules/aws-kms-key"

  description             = "SSM KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = join("", ["alias/", module.this.id, "-ssm"])

  context = module.this.context
}

module "faceit_cw_kms_key" {
  source = "./modules/aws-kms-key"

  description             = "CW LG KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = join("", ["alias/", module.this.id, "-cw"])
  policy                  = data.aws_iam_policy_document.kms_cw_policy.json

  context = module.this.context
}

module "faceit_waf" {
  source = "./modules/aws-waf"

  enabled                            = var.ENABLE_WAF
  managed_rule_group_statement_rules = var.managed_rule_group_statement_rules
  rate_based_statement_rules         = var.rate_based_statement_rules
  xss_match_statement_rules          = var.xss_match_statement_rules
  sqli_match_statement_rules         = var.sqli_match_statement_rules
  association_resource_arns          = [module.faceit_alb.alb_arn]
  default_action                     = "allow"

  context = module.this.context
}

resource "aws_cloudwatch_dashboard" "faceit_cloudwatch_dashboard" {
  dashboard_name = module.this.id
  dashboard_body = jsonencode(local.final_cloudwatch_dashboard_widgets)
}

resource "aws_iam_policy" "faceit_ssm_kms_policy" {
  name = join(module.this.delimiter, [
    module.this.id,
  "ssm-kms"])
  path        = "/"
  tags        = module.this.tags
  description = "Policy to allow certain KMS and SSM access"
  policy      = data.aws_iam_policy_document.ecs_ssm_ksm_policy.json
}
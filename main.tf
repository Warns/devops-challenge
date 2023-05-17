module "faceit_sub_zone" {
  source = "./modules/aws-route53-cluster-zone"

  parent_zone_name = data.aws_route53_zone.faceit_parent_zone.name
  #  parent_zone_name           = "challenge-task.link"
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

module "faceit_ecr" {
  source = "./modules/aws-ecr"

  enabled              = var.enable_ecr
  scan_images_on_push  = var.ecr_scan_images_on_push
  image_tag_mutability = var.ecr_image_tag_mutability

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

#####################
# Central logs lambda
#
#module "central_logs_lambda_label" {
#  source = "./modules/labels"
#
#  name       = "central-logs"
#  attributes = ["lambda"]
#
#  context = module.this.context
#}
#resource "aws_lambda_function" "central_logs_lambda" {
#  count = (var.CENTRAL_LOGS_ENABLE_ISSUER_DIRECTORY || var.CENTRAL_LOGS_ENABLE_PROXY_ISSUER || var.CENTRAL_LOGS_ENABLE_SSI_API) && var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  filename      = join("", data.archive_file.central_logs_lambda_function.*.output_path)
#  function_name = module.central_logs_lambda_label.id
#  role          = aws_iam_role.central_logs_lambda_role[0].arn
#  handler       = "central_logs.lambda_handler"
#
#  source_code_hash = data.archive_file.central_logs_lambda_function.output_base64sha256
#
#  runtime = "nodejs16.x"
#
#  environment {
#    variables = {
#      CENTRAL_LOGS_OPENSEARCH_ENDPOINT = var.CENTRAL_LOGS_OPENSEARCH_ENDPOINT
#    }
#  }
#}
#
#resource "aws_lambda_permission" "central_logs_log_group_invoke_lambda" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  statement_id  = "${module.this.id}-central-logs-lambda-permissions"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.central_logs_lambda[0].function_name
#  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
#  #  source_arn     = "${data.aws_cloudwatch_log_group.proxy_issuer[count.index].arn}:*"
#  source_account = data.aws_caller_identity.current.account_id
#
#  depends_on = [aws_lambda_function.central_logs_lambda]
#}
#
#resource "aws_iam_role" "central_logs_lambda_role" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  name               = module.central_logs_lambda_label.id
#  assume_role_policy = data.aws_iam_policy_document.central_logs_assume_role[0].json
#
#}
#
#data "aws_iam_policy_document" "central_logs_assume_role" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  statement {
#    effect  = "Allow"
#    actions = ["sts:AssumeRole"]
#    principals {
#      type        = "Service"
#      identifiers = ["lambda.amazonaws.com"]
#    }
#  }
#}
#
#resource "aws_iam_role_policy_attachment" "central_logs_lambda_assume_role" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  role       = aws_iam_role.central_logs_lambda_role[0].id
#  policy_arn = join("", [aws_iam_policy.central_logs_policy[0].arn])
#}
#
#resource "aws_iam_policy" "central_logs_policy" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  name = module.central_logs_lambda_label.id
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "es:ESHttp*"
#        ]
#        Effect   = "Allow"
#        Resource = ["arn:aws:es:${data.aws_region.current.name}:${var.CENTRAL_LOGS_ACCOUNT_ID}:domain/${var.CENTRAL_LOGS_DOMAIN_NAME}/*"]
#      },
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "central_logs_lambda_basic_auth" {
#  count = var.CENTRAL_LOGS_ENABLE ? 1 : 0
#
#  role       = aws_iam_role.central_logs_lambda_role[0].id
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#}

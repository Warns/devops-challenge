resource "random_string" "postgresdb_username" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

resource "random_password" "postgresdb_password" {
  length  = 16
  special = true
  numeric = true
  upper   = true
}

resource "random_string" "postgresdb_encryption_key" {
  length  = 15
  special = false
}

#data "archive_file" "central_logs_lambda_function" {
#  type        = "zip"
#  source_file = "${path.module}/resources/central-logs/central_logs.js"
#  output_path = "${path.module}/resources/central-logs/central_logs.zip"
#}

data "aws_caller_identity" "current" {

}
data "aws_region" "current" {

}

data "aws_route53_zone" "faceit_parent_zone" {
  name         = join(".", [module.this.namespace, var.top_level_domain])
  private_zone = false
}

#data "aws_route53_zone" "faceit_parent_zone" {
#  name         = var.top_level_domain
#  private_zone = false
#}

data "aws_iam_policy_document" "kms_cw_policy" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_ssm_ksm_policy" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.faceit_ssm_kms_key.key_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${module.this.namespace}/${module.this.stage}/*"]
  }
}

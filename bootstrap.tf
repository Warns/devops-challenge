#####
# This is used to bootstrap an empty shell AWS account with Route53 zone registration and remote state backend creation. 
# This will be a separate repository with more global configurations such as enabling GuardDuty.
#####

## Create zone
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

## Create backend
#resource "aws_s3_bucket" "terraform_backend_bucket" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  bucket = module.this.id
#}
#
#resource "aws_s3_bucket_versioning" "versioning_example" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  bucket = aws_s3_bucket.terraform_backend_bucket[0].id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}
#
#resource "aws_dynamodb_table" "terraform_backend_lock_table" {
#  count = var.create_terraform_backend ? 1 : 0
#
#  name         = module.this.id
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}

# module "faceit_ecr" {
#   source = "./modules/aws-ecr"

#   enabled              = var.enable_ecr
#   scan_images_on_push  = var.ecr_scan_images_on_push
#   image_tag_mutability = var.ecr_image_tag_mutability

#   context = module.this.context
# }

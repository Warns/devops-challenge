module "faceit_label" {
  source = "./modules/labels"

  enabled = var.enable_faceit_app
  name    = "go"

  context = module.this.context
}

module "faceit_subnets" {
  source = "./modules/aws-dynamic-subnets"

  availability_zones   = var.availability_zones
  vpc_id               = module.faceit_vpc.vpc_id
  igw_id               = module.faceit_vpc.igw_id
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context    = module.faceit_label.context
  cidr_block = var.faceit_cidr_block
}

module "faceit_alb" {
  source = "./modules/aws-alb"

  vpc_id                                  = module.faceit_vpc.vpc_id
  subnet_ids                              = module.faceit_subnets.public_subnet_ids
  internal                                = false
  drop_invalid_header_fields              = true
  cross_zone_load_balancing_enabled       = true
  deletion_protection_enabled             = false
  http_enabled                            = true
  http2_enabled                           = true
  http_redirect                           = true
  https_enabled                           = true
  https_ssl_policy                        = var.https_ssl_policy
  certificate_arn                         = module.faceit_acm_request_certificate.arn
  access_logs_enabled                     = var.enable_alb_access_logs
  lifecycle_rule_enabled                  = var.lifecycle_rule_enabled
  alb_access_logs_s3_bucket_force_destroy = var.force_destroy
  standard_transition_days                = var.standard_transition_days
  glacier_transition_days                 = var.glacier_transition_days
  expiration_days                         = var.expiration_days
  noncurrent_version_transition_days      = var.noncurrent_version_transition_days
  noncurrent_version_expiration_days      = var.noncurrent_version_expiration_days

  context = module.faceit_label.context
}

module "faceit_route53_alias" {
  source = "./modules/aws-route53-alias"

  aliases         = [module.faceit_label.name]
  parent_zone_id  = module.faceit_sub_zone.zone_id
  target_zone_id  = module.faceit_alb.alb_zone_id
  target_dns_name = module.faceit_alb.alb_dns_name
  ipv6_enabled    = true

  context = module.faceit_label.context
}

module "faceit_acm_request_certificate" {
  source = "./modules/aws-acm-request-certificate"

  domain_name                       = join(".", [module.faceit_label.name, module.faceit_sub_zone.zone_name])
  zone_id                           = module.faceit_sub_zone.zone_id
  validation_method                 = "DNS"
  ttl                               = "300"
  subject_alternative_names         = ["*.${module.faceit_sub_zone.zone_name}"]
  process_domain_validation_options = true
  wait_for_certificate_issued       = true

  context = module.faceit_label.context
}

resource "aws_sns_topic" "faceit_sns_topic" {
  name              = module.faceit_label.id
  count             = module.faceit_label.enabled ? 1 : 0
  display_name      = module.faceit_label.id
  tags              = module.faceit_label.tags
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "topic_email_subscription_be" {
  count     = module.faceit_label.enabled ? 1 : 0
  topic_arn = join("", aws_sns_topic.faceit_sns_topic.*.arn)
  protocol  = "email"
  endpoint  = var.alarms_email_group
}

module "faceit_ssm" {
  source = "./modules/aws-ssm-parameter-store"

  parameter_write = local.faceit_parameters_merged
  kms_arn         = module.faceit_ssm_kms_key.key_arn

  context = module.faceit_label.context
}

module "faceit_container_definition" {
  source = "./modules/aws-ecs-container-definition"

  container_name  = module.faceit_label.id
  container_image = var.faceit_container_image
  start_timeout   = var.container_start_timeout
  stop_timeout    = var.container_stop_timeout
  healthcheck     = var.healthcheck
  environment     = var.faceit_container_environment
  port_mappings   = var.faceit_container_port_mappings
  privileged      = var.privileged
  secrets         = module.faceit_ssm.arn_list
  system_controls = var.system_controls
  ulimits         = var.ulimits

  log_configuration = var.cloudwatch_log_group_enabled ? {
    logDriver = var.log_driver
    options = {
    }
    secretOptions = null
  } : null

}

module "faceit_firelens_container_definition" {
  source = "./modules/aws-ecs-container-definition"

  container_name  = var.firelens_sidecar_type.fluentbit
  container_image = var.firelens_sidecar_image

  environment = [
    {
      name  = "REGION"
      value = coalesce(var.AWS_LOGS_REGION, data.aws_region.current.name)
      }, {
      name  = "LOG_GROUP_NAME"
      value = module.faceit_label.id
      }, {
      name  = "LOG_STREAM_NAME"
      value = join("/", [var.log_driver, module.faceit_label.name])
  }]

  log_configuration = var.cloudwatch_log_group_enabled && module.faceit_label.enabled ? {
    logDriver = var.firelens_log_driver
    options = {
      "awslogs-group"         = join(module.this.delimiter, [module.faceit_label.id, var.firelens_sidecar_type.fluentbit])
      "awslogs-stream-prefix" = var.log_driver
      "awslogs-region"        = coalesce(var.AWS_LOGS_REGION, data.aws_region.current.name)
      "awslogs-create-group"  = true
    }
    secretOptions = null
  } : null

  firelens_configuration = var.cloudwatch_log_group_enabled && module.faceit_label.enabled ? {
    type = var.firelens_sidecar_type.fluentbit
    options = {
      "config-file-type" : "file",
      "config-file-value" : "/multi_endpoints.conf"
    }
  } : null
}

module "faceit_service" {
  source = "./modules/aws-ecs-web-app"

  vpc_id                         = module.faceit_vpc.vpc_id
  ignore_changes_task_definition = false

  # Container
  container_definition = module.faceit_container_definition.json_map_encoded
  init_containers      = [{ container_definition = module.faceit_firelens_container_definition.json_map_encoded, condition = "START" }]

  # Authentication
  authentication_type                           = var.authentication_type
  alb_ingress_listener_unauthenticated_priority = var.alb_ingress_listener_unauthenticated_priority
  alb_ingress_listener_authenticated_priority   = var.alb_ingress_listener_authenticated_priority
  alb_ingress_unauthenticated_paths             = var.alb_ingress_unauthenticated_paths

  # ECS
  ecs_private_subnet_ids            = module.faceit_subnets.private_subnet_ids
  ecs_cluster_arn                   = aws_ecs_cluster.faceit_cluster.arn
  ecs_cluster_name                  = aws_ecs_cluster.faceit_cluster.name
  ecs_security_group_ids            = var.ecs_security_group_ids
  health_check_grace_period_seconds = var.faceit_health_check_grace_period_seconds
  desired_count                     = var.faceit_desired_count
  launch_type                       = var.launch_type
  container_port                    = var.faceit_container_port
  task_cpu                          = var.faceit_task_cpu
  task_memory                       = var.faceit_task_memory
  task_policy_arns                  = concat([aws_iam_policy.faceit_ssm_kms_policy.arn])

  # ALB
  alb_arn_suffix                               = module.faceit_alb.alb_arn_suffix
  alb_security_group                           = module.faceit_alb.security_group_id
  use_alb_security_group                       = true
  alb_ingress_unauthenticated_listener_arns    = [module.faceit_alb.https_listener_arn]
  alb_ingress_healthcheck_path                 = var.faceit_alb_ingress_healthcheck_path
  alb_ingress_healthcheck_protocol             = var.alb_ingress_healthcheck_protocol
  alb_ingress_health_check_healthy_threshold   = var.alb_ingress_health_check_healthy_threshold
  alb_ingress_health_check_unhealthy_threshold = var.alb_ingress_health_check_unhealthy_threshold
  alb_ingress_health_check_interval            = var.alb_ingress_health_check_interval
  alb_ingress_health_check_timeout             = var.alb_ingress_health_check_timeout

  # Environment
  container_environment = var.faceit_container_environment
  secrets               = var.faceit_secrets

  # Autoscaling
  autoscaling_enabled               = var.autoscaling_enabled && module.faceit_label.enabled
  autoscaling_dimension             = var.faceit_autoscaling_dimension
  autoscaling_min_capacity          = var.faceit_autoscaling_min_capacity
  autoscaling_max_capacity          = var.faceit_autoscaling_max_capacity
  autoscaling_scale_up_adjustment   = var.faceit_autoscaling_scale_up_adjustment
  autoscaling_scale_up_cooldown     = var.faceit_autoscaling_scale_up_cooldown
  autoscaling_scale_down_adjustment = var.faceit_autoscaling_scale_down_adjustment
  autoscaling_scale_down_cooldown   = var.faceit_autoscaling_scale_down_cooldown

  # ECS alarms
  ecs_alarms_enabled                                    = var.ecs_alarms_enabled && module.faceit_label.enabled
  ecs_alarms_cpu_utilization_high_threshold             = var.faceit_ecs_alarms_cpu_utilization_high_threshold
  ecs_alarms_cpu_utilization_high_evaluation_periods    = var.faceit_ecs_alarms_cpu_utilization_high_evaluation_periods
  ecs_alarms_cpu_utilization_high_period                = var.faceit_ecs_alarms_cpu_utilization_high_period
  ecs_alarms_cpu_utilization_low_threshold              = var.faceit_ecs_alarms_cpu_utilization_low_threshold
  ecs_alarms_cpu_utilization_low_evaluation_periods     = var.faceit_ecs_alarms_cpu_utilization_low_evaluation_periods
  ecs_alarms_cpu_utilization_low_period                 = var.faceit_ecs_alarms_cpu_utilization_low_period
  ecs_alarms_memory_utilization_high_threshold          = var.faceit_ecs_alarms_memory_utilization_high_threshold
  ecs_alarms_memory_utilization_high_evaluation_periods = var.faceit_ecs_alarms_memory_utilization_high_evaluation_periods
  ecs_alarms_memory_utilization_high_period             = var.faceit_ecs_alarms_memory_utilization_high_period
  ecs_alarms_memory_utilization_low_threshold           = var.faceit_ecs_alarms_memory_utilization_low_threshold
  ecs_alarms_memory_utilization_low_evaluation_periods  = var.faceit_ecs_alarms_memory_utilization_low_evaluation_periods
  ecs_alarms_memory_utilization_low_period              = var.faceit_ecs_alarms_memory_utilization_low_period
  ecs_alarms_cpu_utilization_high_alarm_actions         = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_cpu_utilization_high_ok_actions            = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_cpu_utilization_low_alarm_actions          = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_cpu_utilization_low_ok_actions             = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_memory_utilization_high_alarm_actions      = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_memory_utilization_high_ok_actions         = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_memory_utilization_low_alarm_actions       = aws_sns_topic.faceit_sns_topic[*].arn
  ecs_alarms_memory_utilization_low_ok_actions          = aws_sns_topic.faceit_sns_topic[*].arn

  # ALB and Target Group alarms
  alb_target_group_alarms_enabled                   = var.alb_target_group_alarms_enabled && module.faceit_label.enabled
  alb_target_group_alarms_evaluation_periods        = var.alb_target_group_alarms_evaluation_periods
  alb_target_group_alarms_period                    = var.alb_target_group_alarms_period
  alb_target_group_alarms_3xx_threshold             = var.alb_target_group_alarms_3xx_threshold
  alb_target_group_alarms_4xx_threshold             = var.alb_target_group_alarms_4xx_threshold
  alb_target_group_alarms_5xx_threshold             = var.alb_target_group_alarms_5xx_threshold
  alb_target_group_alarms_response_time_threshold   = var.alb_target_group_alarms_response_time_threshold
  alb_target_group_alarms_alarm_actions             = aws_sns_topic.faceit_sns_topic[*].arn
  alb_target_group_alarms_ok_actions                = aws_sns_topic.faceit_sns_topic[*].arn
  alb_target_group_alarms_insufficient_data_actions = aws_sns_topic.faceit_sns_topic[*].arn

  log_retention_in_days        = var.cw_log_retention_in_days
  cloudwatch_log_group_enabled = module.faceit_label.enabled

  depends_on = [module.faceit_alb]
  context    = module.faceit_label.context
}

# RDS Postgres
module "rds_postgres_label" {
  source = "./modules/labels"

  enabled = var.enable_rds_postgres && var.enable_faceit_app
  name    = var.rds_postgres_name

  context = module.this.context
}

module "rds_postgres_subnets" {
  source = "./modules/aws-multi-az-subnets"

  availability_zones = var.availability_zones
  vpc_id             = module.faceit_vpc.vpc_id
  cidr_block         = var.rds_postgres_cidr_block
  type               = "private"

  context = module.rds_postgres_label.context
}

module "rds_postgres_cluster" {
  source = "./modules/aws-rds-cluster"

  db_name                          = module.rds_postgres_label.name
  vpc_id                           = module.faceit_vpc.vpc_id
  subnets                          = values(module.rds_postgres_subnets.az_subnet_ids)
  security_groups                  = [module.faceit_service.ecs_service_security_group_id, module.rds_postgres_cluster.security_group_id]
  admin_user                       = random_string.postgresdb_username.result
  admin_password                   = random_password.postgresdb_password.result
  db_port                          = var.rds_postgres_db_port
  engine                           = var.rds_postgres_engine
  engine_mode                      = var.rds_postgres_engine_mode
  cluster_family                   = var.rds_postgres_cluster_family
  cluster_size                     = var.rds_postgres_cluster_size
  deletion_protection              = var.rds_postgres_deletion_protection
  enhanced_monitoring_role_enabled = var.rds_postgres_enhanced_monitoring_role_enabled
  rds_monitoring_interval          = var.rds_postgres_rds_monitoring_interval
  enable_http_endpoint             = true
  auto_minor_version_upgrade       = true
  storage_encrypted                = true


  scaling_configuration = [
    {
      auto_pause               = true
      max_capacity             = 32
      min_capacity             = 2
      seconds_until_auto_pause = 300
      timeout_action           = "ForceApplyCapacityChange"
    }
  ]

  context = module.rds_postgres_label.context
}
############### AWS GENERAL ###############
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

############### ECR ###############
variable "enable_ecr" {
  type        = bool
  description = "A boolean to enable/disable AWS ECR"
  default     = true
}

variable "ecr_scan_images_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not (false)"
  default     = true
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the ecr repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
  default     = "IMMUTABLE"
}

############### ECS SERVICE ###############
variable "launch_type" {
  type        = string
  description = "The ECS launch type: FARGATE - EC2"
  default     = "FARGATE"
}

variable "ecs_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to allow into ECS Service"
  default     = []
}

variable "container_start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container"
  default     = 30
}

variable "container_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own"
  default     = 30
}

variable "privileged" {
  type        = string
  description = "When this variable is `true`, the container is given elevated privileges on the host container instance (similar to the root user). This parameter is not supported for Windows containers or tasks using the Fargate launch type. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = null
}

variable "system_controls" {
  type        = list(map(string))
  description = "A list of namespaced kernel parameters to set in the container, mapping to the --sysctl option to docker run. This is a list of maps: { namespace = \"\", value = \"\"}"
  default     = null
}

variable "ulimits" {
  type = list(object({
    name      = string
    softLimit = number
    hardLimit = number
  }))
  description = "The ulimits to configure for the container. This is a list of maps. Each map should contain \"name\", \"softLimit\" and \"hardLimit\""
  default     = []
}

############### APPLICATION LB ###############
variable "https_ssl_policy" {
  type        = string
  description = "AWS ALB https ssl policy"
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "alb_ingress_healthcheck_protocol" {
  type        = string
  description = "The protocol to use to connect with the target. Defaults to `HTTP`. Not applicable when `target_type` is `lambda`"
  default     = "HTTP"
}

variable "alb_ingress_health_check_healthy_threshold" {
  type        = number
  description = "The number of consecutive health checks successes required before healthy"
  default     = 2
}

variable "alb_ingress_health_check_unhealthy_threshold" {
  type        = number
  description = "The number of consecutive health check failures required before unhealthy"
  default     = 10
}

variable "alb_ingress_health_check_interval" {
  type        = number
  description = "The duration in seconds in between health checks"
  default     = 15
}

variable "alb_ingress_health_check_timeout" {
  type        = number
  description = "The amount of time to wait in seconds before failing a health check request"
  default     = 10
}

variable "alb_ingress_listener_unauthenticated_priority" {
  type        = number
  description = "The priority for the rules without authentication, betwe§en 1 and 50000 (1 being highest priority). Must be different from `alb_ingress_listener_authenticated_priority` since a listener can't have multiple rules with the same priority"
  default     = 1000
}

variable "alb_ingress_listener_authenticated_priority" {
  type        = number
  description = "The priority for the rules with authentication, between 1 and 50000 (1 being highest priority). Must be different from `alb_ingress_listener_unauthenticated_priority` since a listener can't have multiple rules with the same priority"
  default     = 300
}

variable "alb_ingress_unauthenticated_paths" {
  type        = list(string)
  description = "Unauthenticated path pattern to match (a maximum of 1 can be defined)"
  default     = ["/*"]
}

variable "authentication_type" {
  type        = string
  description = "Authentication type. Supported values are `COGNITO` and `OIDC`"
  default     = ""
}

############### CLOUDWATCH ALARMS ###############

variable "alarms_email_group" {
  type        = string
  description = "Email group that will receive alarms"
  default     = "snickns@gmail.com"
}

variable "alb_target_group_alarms_enabled" {
  type        = bool
  description = "A boolean to enable/disable CloudWatch Alarms for ALB Target metrics"
  default     = true
}

variable "alb_target_group_alarms_3xx_threshold" {
  type        = number
  description = "The maximum number of 3XX HTTPCodes in a given period for ECS Service"
  default     = 25
}

variable "alb_target_group_alarms_4xx_threshold" {
  type        = number
  description = "The maximum number of 4XX HTTPCodes in a given period for ECS Service"
  default     = 25
}

variable "alb_target_group_alarms_5xx_threshold" {
  type        = number
  description = "The maximum number of 5XX HTTPCodes in a given period for ECS Service"
  default     = 25
}

variable "alb_target_group_alarms_response_time_threshold" {
  type        = number
  description = "The maximum ALB Target Group response time"
  default     = 0.5
}

variable "alb_target_group_alarms_period" {
  type        = number
  description = "The period (in seconds) to analyze for ALB CloudWatch Alarms"
  default     = 300
}

variable "alb_target_group_alarms_evaluation_periods" {
  type        = number
  description = "The number of periods to analyze for ALB CloudWatch Alarms"
  default     = 1
}

variable "ecs_alarms_enabled" {
  type        = bool
  description = "A boolean to enable/disable CloudWatch Alarms for ECS Service metrics"
  default     = true
}

############### ECS AUTOSCALING ###############
variable "autoscaling_enabled" {
  type        = bool
  description = "A boolean to enable/disable Autoscaling policy for ECS Service"
  default     = true
}

############### ROUTE53 ###############
variable "top_level_domain" {
  type        = string
  description = "Top level domain to create subdomains in Route53"
}

variable "cross_account_parent_zone_enabled" {
  type        = bool
  default     = true
  description = "Adding cross account nameserver to parent zone."
}


############### ALB ACCESS LOGS ###############
variable "enable_alb_access_logs" {
  type        = bool
  description = "Enable ALB access logs"
  default     = false
}

############### CLOUDWATCH LOGS ###############
variable "cloudwatch_log_group_enabled" {
  type        = bool
  description = "A boolean to disable cloudwatch log group creation"
  default     = true
}

variable "AWS_LOGS_REGION" {
  type        = string
  description = "The region for the AWS Cloudwatch Logs group"
  default     = null
}

variable "log_driver" {
  type        = string
  description = "The log driver to use for the container"
  default     = "awsfirelens"
}

variable "firelens_log_driver" {
  type        = string
  description = "The log driver to use for the sidecar container"
  default     = "awslogs"
}

variable "firelens_sidecar_type" {
  type = object({
    fluentbit = string
    fluentd   = string
  })
  description = "Firelens container image: fluentbit - fluentd"
  default = {
    fluentbit = "fluentbit"
    fluentd   = "fluentd"
  }
}

variable "firelens_sidecar_image" {
  type        = string
  description = "Firelens container image: fluentbit - fluentd"
  default     = "072271489564.dkr.ecr.eu-west-1.amazonaws.com/fluentbit:latest"
}

variable "cw_log_retention_in_days" {
  type        = number
  description = "The number of days to retain logs for the log group"
  default     = 7
}

############### VPC FLOW LOGS ###############
variable "ENABLE_VPC_FLOW_LOGS" {
  type        = bool
  description = "Enable VPC flow logs"
  default     = false
}

variable "vpc_flow_logs_name" {
  type        = string
  description = "VPC flow logs related resource names"
  default     = "vpc-flow-logs"
}

variable "flow_logs_traffic_type" {
  type        = string
  description = "The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL`"
  default     = "ALL"
}

variable "flow_log_enabled" {
  type        = bool
  description = "Enable/disable the Flow Log creation. Useful in multi-account environments where the bucket is in one account, but VPC Flow Logs are in different accounts"
  default     = true
}

############### LOGS COMMON LIFECYCLE ###############
variable "lifecycle_rule_enabled" {
  type        = bool
  description = "Enable lifecycle events buckets"
  default     = true
}

variable "force_destroy" {
  type        = bool
  description = "Enable S3 buckets force destruction"
  default     = true
}

variable "standard_transition_days" {
  type        = number
  description = "Number of days to persist in the standard storage tier before moving to the infrequent access tier"
  default     = 30
}

variable "glacier_transition_days" {
  type        = number
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = 60
}

variable "expiration_days" {
  type        = number
  description = "Number of days after which to expunge the objects"
  default     = 90
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "Specifies when noncurrent object versions transitions"
  default     = 30
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Specifies when noncurrent object versions expire"
  default     = 90
}

############### AWS WAF ###############
variable "ENABLE_WAF" {
  type        = bool
  description = "Enable Waf for AWS ALBs"
  default     = false
}

variable "rate_based_statement_rules" {
  type        = list(any)
  description = "Rate Limit Rules"
  default = [
    {
      name     = "SMS-Rate-Limit"
      priority = 3
      action   = "block"
      statement = {
        override_action    = "none"
        limit              = 100
        aggregate_key_type = "IP"
        scope_down_statement = {
          byte_match_statement = {
            search_string = "/send-sms"
            text_transformation = {
              priority = 0
              type     = "NONE"
            }
            field_to_match = {
              all_query_arguments = "{}"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "SMS-Rate-Limit"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "EMAIL-Rate-Limit"
      priority = 4
      action   = "block"
      statement = {
        override_action    = "none"
        limit              = 100
        aggregate_key_type = "IP"
        scope_down_statement = {
          byte_match_statement = {
            search_string = "/send-email"
            text_transformation = {
              priority = 0
              type     = "NONE"
            }
            field_to_match = {
              all_query_arguments = "{}"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "EMAIL-Rate-Limit"
        sampled_requests_enabled   = true
      }
    }

  ]

}

variable "sqli_match_statement_rules" {
  type        = list(any)
  description = "Block SQL Injection Attacks"
  default = [
    {
      name     = "Block-SQL-Injection-Attacks"
      priority = 1
      action   = "block"
      statement = {
        override_action = "none"
        text_transformation = [
          {
            type     = "URL_DECODE"
            priority = 1
          },
          {
            type     = "HTML_ENTITY_DECODE"
            priority = 2
          }
        ]
        field_to_match = {
          query_string = {}
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "Block-SQL-Injection-Attacks"
        sampled_requests_enabled   = true
      }
    }
  ]
}

variable "xss_match_statement_rules" {
  type        = list(any)
  description = "Block XSS Injection Attacks"
  default = [
    {
      name     = "Block-XSS-Injection-Attacks"
      priority = 0
      action   = "block"
      statement = {
        override_action = "none"
        text_transformation = [
          {
            type     = "URL_DECODE"
            priority = 1
          },
          {
            type     = "HTML_ENTITY_DECODE"
            priority = 2
          }
        ]
        field_to_match = {
          uri_path = "{}"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "Block-XSS-Injection-Attacks"
        sampled_requests_enabled   = true
      }
    }
  ]
}

variable "managed_rule_group_statement_rules" {
  type        = list(any)
  description = "AWS Managed Ruleset"
  default = [
    {
      name            = "Rule-AWSManagedRulesCommonRuleSet"
      override_action = "count"
      priority        = 20

      statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "common-rule-set-metric"
      }
    },
    {
      name            = "Rule-AWSManagedRulesKnownBadInputsRuleSet"
      override_action = "count"
      priority        = 21

      statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "bad-input-rule-set-metric"
      }
    },
    {
      name            = "Rule-AWSManagedRulesAmazonIpReputationList"
      override_action = "count"
      priority        = 22

      statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "ip-reputation-rule-set-metric"
      }
    },
    {
      name            = "Rule-AWSManagedRulesLinuxRuleSet"
      override_action = "count"
      priority        = 23

      statement = {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "linux-rule-set-metric"
      }
    },
    {
      name            = "Rule-AWSManagedRulesUnixRuleSet"
      override_action = "count"
      priority        = 24

      statement = {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "unix-rule-set-metric"
      }
    },
    {
      name            = "Rule-AWSManagedRulesAdminProtectionRuleSet"
      override_action = "count"
      priority        = 25

      statement = {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = false
        metric_name                = "admin--protection-rule-set-metric"
      }
    }
  ]
}

############### POSTGRES SQL ###############
variable "enable_rds_postgres" {
  type        = bool
  description = "Enable PostgresSQL RDS cluster"
  default     = true
}

variable "rds_postgres_name" {
  type        = string
  description = "Database name"
  default     = "postgresdb"
}

variable "rds_postgres_cidr_block" {
  type        = string
  description = "RDS CIDR block"
}

variable "rds_postgres_engine" {
  type        = string
  description = "The name of the database engine to be used for this DB cluster. Valid values: `aurora`, `aurora-mysql`, `aurora-postgresql`"
  default     = "aurora-postgresql"
}

variable "rds_postgres_engine_mode" {
  type        = string
  description = "The database engine mode. Valid values: `parallelquery`, `provisioned`, `serverless`"
  default     = "serverless"
}

variable "rds_postgres_cluster_size" {
  type        = number
  description = "Number of DB instances to create in the cluster"
  default     = 0
}

variable "rds_postgres_cluster_family" {
  type        = string
  description = "The family of the DB cluster parameter group"
  default     = "aurora-postgresql10"
}

variable "rds_postgres_db_port" {
  type        = number
  description = "RDS Database port"
  default     = 5432
}

variable "rds_postgres_deletion_protection" {
  type        = bool
  description = "If the DB instance should have deletion protection enabled"
  default     = false
}

variable "rds_postgres_enhanced_monitoring_role_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable the creation of the enhanced monitoring IAM role. If set to `false`, the module will not create a new role and will use `rds_monitoring_role_arn` for enhanced monitoring"
  default     = false
}

variable "rds_postgres_rds_monitoring_interval" {
  type        = number
  description = "The interval, in seconds, between points when enhanced monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60"
  default     = 0
}
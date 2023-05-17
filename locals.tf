locals {
  faceit_parameters_filtered = [
    for ssm_val in local.faceit_parameter_write_dynamic : ssm_val
    if !contains([for env_val in var.faceit_parameter_write : env_val.name], ssm_val.name)
  ]

  faceit_parameters_merged = concat(var.faceit_parameter_write, local.faceit_parameters_filtered)

  service_enablement = [
    {
      enabled      = var.enable_faceit_app
      service_name = module.faceit_service.ecs_service_name
      lb_arn       = module.faceit_alb.alb_arn_suffix
    }
  ]

  db_postgres_url = module.rds_postgres_label.enabled ? "jdbc:postgresql://${module.rds_postgres_cluster.endpoint}:5432/${module.rds_postgres_cluster.database_name}" : "NA"
  current_domain  = module.faceit_label.enabled ? module.faceit_route53_alias.hostnames[0] : "NA"
  #  cookie_domain         = data.aws_route53_zone.faceit_parent_zone.name

  faceit_parameter_write_dynamic = [
    {
      name      = "DB_USERNAME"
      value     = random_string.postgresdb_username.result
      type      = "SecureString"
      overwrite = "true"
    },
    {
      name      = "DB_PASSWORD"
      value     = random_password.postgresdb_password.result
      type      = "SecureString"
      overwrite = "true"
    },
    {
      name      = "DB_ENCRYPTION_KEY"
      value     = md5(random_string.postgresdb_encryption_key.result)
      type      = "SecureString"
      overwrite = "true"
    },
    {
      name      = "DB_URL"
      value     = local.db_postgres_url
      type      = "String"
      overwrite = "true"
    },
    {
      name      = "SERVER_PORT"
      value     = var.faceit_container_port
      type      = "String"
      overwrite = "true"
    },
    {
      name      = "CURRENT_DOMAIN"
      value     = local.current_domain
      type      = "String"
      overwrite = "true"
    }
  ]

  common_cloudwatch_dashboard_widget_values = {
    "height" = 6
    "width"  = 6
    "type"   = "metric"
  }

  final_cloudwatch_dashboard_widgets = {
    "widgets" = [
      for i in local.cloudwatch_dashboard_widgets : merge(i, local.common_cloudwatch_dashboard_widget_values)
    ]
  }

  cloudwatch_dashboard_widgets = [
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = [
          [
            "ECS/ContainerInsights",
            "TaskCount",
            "ClusterName",
            module.this.id,
            {
              stat = "Average"
            },
          ],
        ]
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT3H0M0S"
        "timezone" = "Local"
        "title"    = "ECS Task Count"
        "view"     = "timeSeries"
      }
      x = 0
      y = 0
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = [
          [
            "ECS/ContainerInsights",
            "ServiceCount",
            "ClusterName",
            module.this.id,
            {
              stat = "Average"
            },
          ],
        ]
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "ECS Service Count"
        "view"     = "timeSeries"
      }
      x = 6
      y = 0
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = [
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "PendingTaskCount",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              stat = "Average"
            }
          ] if value.enabled == true
        ]
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "Number of Pending Tasks"
        "view"     = "timeSeries"
      }
      x = 18
      y = 0
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = concat([
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "CpuReserved",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              id      = "mm0m${index}"
              stat    = "Sum"
              visible = false
            }
          ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              "ECS/ContainerInsights",
              "CpuUtilized",
              "ClusterName",
              module.this.id,
              "ServiceName",
              value.service_name,
              {
                id      = "mm1m${index}"
                stat    = "Sum"
                visible = false
              }
            ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              {
                expression = "mm1m${index} * 100 / mm0m${index}"
                id         = "expr1m${index}"
                label      = value.service_name
                stat       = "Average"
              }
            ] if value.enabled == true
          ]
        )
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "CPU Utilization"
        "view"     = "timeSeries"
        "yAxis" = {
          "left" = {
            "label"     = "Percent"
            "min"       = 0
            "showUnits" = false
          }
        }
      }
      x = 0
      y = 6
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = concat([
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "MemoryReserved",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              id      = "mm0m${index}"
              stat    = "Sum"
              visible = false
            }
          ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              "ECS/ContainerInsights",
              "MemoryUtilized",
              "ClusterName",
              module.this.id,
              "ServiceName",
              value.service_name,
              {
                id      = "mm1m${index}"
                stat    = "Sum"
                visible = false
              }
            ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              {
                expression = "mm1m${index} * 100 / mm0m${index}"
                id         = "expr1m${index}"
                label      = value.service_name
                stat       = "Average"
              }
            ] if value.enabled == true
          ]
        )
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "Memory Utilization"
        "view"     = "timeSeries"
        "yAxis" = {
          "left" = {
            "label"     = "Percent"
            "min"       = 0
            "showUnits" = false
          }
        }
      }
      x = 6
      y = 6
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = [
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "RunningTaskCount",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              stat = "Average"
            }
          ] if value.enabled == true
        ]
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "Number of Running Tasks"
        "view"     = "timeSeries"
      }
      x = 12
      y = 0
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = concat([
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "NetworkRxBytes",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              id      = "mm0m${index}"
              stat    = "Average"
              visible = false
            }
          ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              {
                expression = "mm0m${index}"
                id         = "expr1m${index}"
                label      = value.service_name
                stat       = "Average"
              }
            ] if value.enabled == true
          ]
        )
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "Network RX"
        "view"     = "timeSeries"
        "yAxis" = {
          "left" = {
            "label"     = "Bytes/Second"
            "showUnits" = false
          }
        }
      }
      x = 12
      y = 6
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "liveData" = false
        "metrics" = concat([
          for index, value in local.service_enablement : [
            "ECS/ContainerInsights",
            "NetworkTxBytes",
            "ClusterName",
            module.this.id,
            "ServiceName",
            value.service_name,
            {
              id      = "mm0m${index}"
              stat    = "Average"
              visible = false
            }
          ] if value.enabled == true
          ],
          [
            for index, value in local.service_enablement : [
              {
                expression = "mm0m${index}"
                id         = "expr1m${index}"
                label      = value.service_name
                stat       = "Average"
              }
            ] if value.enabled == true
          ]
        )
        "period"   = 60
        "region"   = data.aws_region.current.name
        "stacked"  = false
        "start"    = "-P0DT6H0M0S"
        "timezone" = "Local"
        "title"    = "Network TX"
        "view"     = "timeSeries"
        "yAxis" = {
          "left" = {
            "label"     = "Bytes/Second"
            "showUnits" = false
          }
        }
      }
      x = 18
      y = 6
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "RequestCount",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "Request Count"
        "view"    = "timeSeries"
      }
      x = 0
      y = 12
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "HTTPCode_Target_2XX_Count",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "TG 2xx "
        "view"    = "timeSeries"
      }
      x = 6
      y = 12
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "HTTPCode_Target_4XX_Count",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "TG 4xx"
        "view"    = "timeSeries"
      }
      x = 12
      y = 12
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer",
            value.lb_arn,
            {
              id     = "m${index}"
              region = data.aws_region.current.name
              stat   = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "TG 5xx"
        "view"    = "timeSeries"
      }
      x = 18
      y = 12
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "ActiveConnectionCount",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "Active Connection Count"
        "view"    = "timeSeries"
      }
      x = 0
      y = 18
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "NewConnectionCount",
            "LoadBalancer",
            value.lb_arn,
            {
              id     = "m${index}"
              region = data.aws_region.current.name
              stat   = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "New Connection Count"
        "view"    = "timeSeries"
      }
      x = 6
      y = 18
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "TargetResponseTime",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Average"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "TG Response Time"
        "view"    = "timeSeries"
      }
      x = 18
      y = 18
    },
    {
      properties = {
        "end" = "P0D"
        "legend" = {
          "position" = "bottom"
        }
        "metrics" = [
          for index, value in local.service_enablement : [
            "AWS/ApplicationELB",
            "HTTP_Redirect_Count",
            "LoadBalancer",
            value.lb_arn,
            {
              id   = "m${index}"
              stat = "Sum"
            }
          ] if value.enabled == true
        ]
        "period"  = 300
        "region"  = data.aws_region.current.name
        "stacked" = false
        "start"   = "-PT3H"
        "title"   = "HTTP Redirect Count"
        "view"    = "timeSeries"
      }
      x = 12
      y = 18
    },
  ]

  cis_rules = {
    "authorization-failure-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an unauthorized API call is made."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "auth-failure-exceeded"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\")}"
      "metric_name"               = "AuthorizationFailureCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "aws-config-change-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when AWS Config changes."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "aws-config-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder)||($.eventName=DeleteDeliveryChannel)||($.eventName=PutDeliveryChannel)||($.eventName=PutConfigurationRecorder))}"
      "metric_name"               = "AWSConfigChangeCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "cloud-trail-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to create, update or delete a .cloudtrail. trail, or to start or stop logging to a trail."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "cloudtrail-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
      "metric_name"               = "CloudTrailEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "console-sign-in-failure-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an unauthenticated API call is made to sign into the console."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "unauthenticated-apicall-console-login"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "3"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
      "metric_name"               = "ConsoleSignInFailureCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "console-signin-without-mfa-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when a user logs into the console without MFA."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "non-mfa-login"
      "alarm_period"              = "86400"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
      "metric_name"               = "ConsoleSignInWithoutMfaCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "gateway-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to create, update or delete a Customer or Internet Gateway."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "internet-gw-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
      "metric_name"               = "GatewayEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "iam-policy-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to change an IAM policy."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "iam-policy-changed"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) ||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
      "metric_name"               = "IAMPolicyEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "kms-key-pending-deletion-error-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when a customer created KMS key is pending deletion."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "kms-key-deleted"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion))}"
      "metric_name"               = "KMSKeyPendingDeletionErrorCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "network-acl-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to create, update or delete a Network ACL."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "network-acl-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
      "metric_name"               = "NetworkAclEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "route-table-changes-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when route table changes are detected."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "route-table-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
      "metric_name"               = "RouteTableChangesCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "s3-bucket-policy-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to S3 to put or delete a Bucket Lifecycle Policy, Bucket Policy or Bucket ACL."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "s3-bucket-policy-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
      "metric_name"               = "S3BucketPolicyEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "security-group-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to create, update or delete a Security Group."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "security-group-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
      "metric_name"               = "SecurityGroupEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "use-of-root-account-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when root credenitals are used."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "root-account-used"
      "alarm_period"              = "86400"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
      "metric_name"               = "UseOfRootAccountCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "vpc-event-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an API call is made to create, update or delete a VPC, VPC peering connection or VPC connection to classic."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "vpc-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
      "metric_name"               = "VpcEventCount"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
    "dynamodb-write-count" = {
      "alarm_comparison_operator" = "GreaterThanOrEqualToThreshold"
      "alarm_description"         = "Alarms when an dynamodb write API call is made."
      "alarm_evaluation_periods"  = "1"
      "alarm_name"                = "dynamodb-table-modified"
      "alarm_period"              = "300"
      "alarm_statistic"           = "Sum"
      "alarm_threshold"           = "1"
      "alarm_treat_missing_data"  = "notBreaching"
      "filter_pattern"            = "{(($.eventName = PutItem) || ($.eventName = DeleteItem) || ($.eventName = CreateTable) || ($.eventName = DeleteTable) || ($.eventName = UpdateTable) || ($.eventName = UpdateItem)) && ($.eventSource = dynamodb.amazonaws.com)}"
      "metric_name"               = "DynamoDBTableChanged"
      "metric_namespace"          = "CISBenchmark"
      "metric_value"              = "1"
    }
  }
}
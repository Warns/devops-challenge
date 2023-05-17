############### FACEIT-GENERIC ###############
variable "enable_faceit_app" {
  type        = bool
  description = "Enable/Disable faceit app"
}

#variable "service_name" {
#  type        = string
#  description = "Name Of Portal Backend"
#  default     = "faceit"
#}

variable "faceit_cidr_block" {
  type        = string
  description = "Faceit CIDR block"
}

variable "faceit_container_image" {
  type        = string
  description = "The default container image to use in container definition"
  default     = "093013615152.dkr.ecr.eu-west-1.amazonaws.com/faceit-app:latest"
}

variable "faceit_container_port" {
  type        = number
  description = "The port number on the container bound to assigned host_port"
  default     = 8080
}

variable "faceit_container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"
  default = [
    {
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }
  ]
}

variable "faceit_container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment list of maps of variables to pass to the container"
  default     = []
}

variable "faceit_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets list of maps of variables to pass to the container"
  default     = null
}

variable "faceit_parameter_write" {
  type        = list(map(string))
  description = "List of maps with the parameter values to write to SSM Parameter Store"
  default     = null
}

variable "faceit_task_cpu" {
  type        = number
  description = "The number of CPU units used by the task. If unspecified, it will default to `container_cpu`. If using `FARGATE` launch type `task_cpu` must match supported memory values (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = "256"
}

variable "faceit_task_memory" {
  type        = number
  description = "The amount of memory (in MiB) used by the task. If unspecified, it will default to `container_memory`. If using Fargate launch type `task_memory` must match supported cpu value (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = "512"
}

variable "healthcheck" {
  type = object({
    command     = list(string)
    retries     = number
    timeout     = number
    interval    = number
    startPeriod = number
  })
  description = "A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default = {
    command = [
      "CMD-SHELL",
      "wget  -t1 -nv -O /dev/null -q 'http://localhost:8080/actuator/health' || exit 1"
    ],
    retries     = 6
    timeout     = 30
    interval    = 60
    startPeriod = 0
  }
}

variable "faceit_health_check_grace_period_seconds" {
  type        = number
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers"
  default     = 30
}

variable "faceit_desired_count" {
  type        = number
  description = "The desired number of tasks to start with"
  default     = 1
}

variable "faceit_autoscaling_min_capacity" {
  type        = number
  description = "Minimum number of running instances of a Service"
  default     = 1
}

variable "faceit_autoscaling_dimension" {
  type        = string
  description = "Dimension to autoscale on (valid options: cpu, memory)"
  default     = "cpu"
}

variable "faceit_autoscaling_max_capacity" {
  type        = number
  description = "Maximum number of running instances of a Service"
  default     = 1
}

variable "faceit_autoscaling_scale_up_adjustment" {
  type        = number
  description = "Scaling adjustment to make during scale up event"
  default     = 1
}

variable "faceit_autoscaling_scale_up_cooldown" {
  type        = number
  description = "Period (in seconds) to wait between scale up events"
  default     = 30
}

variable "faceit_autoscaling_scale_down_adjustment" {
  type        = number
  description = "Scaling adjustment to make during scale down event"
  default     = 1
}

variable "faceit_autoscaling_scale_down_cooldown" {
  type        = number
  description = "Period (in seconds) to wait between scale down events"
  default     = 120
}

variable "faceit_alb_ingress_healthcheck_path" {
  type        = string
  description = "The path of the proxy-issuer healthcheck which the ALB checks"
  default     = "/health"
}

variable "alb_ingress_stickiness_enabled" {
  type        = bool
  default     = false
  description = "Boolean to enable / disable `stickiness`. Default is `true`"
}

variable "faceit_ecs_alarms_cpu_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of CPU utilization average"
  default     = 60
}

variable "faceit_ecs_alarms_cpu_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 1
}

variable "faceit_ecs_alarms_cpu_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 60
}

variable "faceit_ecs_alarms_cpu_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of CPU utilization average"
  default     = 20
}

variable "faceit_ecs_alarms_cpu_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 1
}

variable "faceit_ecs_alarms_cpu_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 60
}

variable "faceit_ecs_alarms_memory_utilization_high_threshold" {
  type        = number
  description = "The maximum percentage of Memory utilization average"
  default     = 60
}

variable "faceit_ecs_alarms_memory_utilization_high_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 1
}

variable "faceit_ecs_alarms_memory_utilization_high_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 60
}

variable "faceit_ecs_alarms_memory_utilization_low_threshold" {
  type        = number
  description = "The minimum percentage of Memory utilization average"
  default     = 5
}

variable "faceit_ecs_alarms_memory_utilization_low_evaluation_periods" {
  type        = number
  description = "Number of periods to evaluate for the alarm"
  default     = 1
}

variable "faceit_ecs_alarms_memory_utilization_low_period" {
  type        = number
  description = "Duration in seconds to evaluate for the alarm"
  default     = 60
}
#
## Central logs lambda function
#variable "lambda_reserved_concurrent_executions" {
#  type        = number
#  description = "Amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1."
#  default     = -1
#}
#
#variable "deletion_window_in_days" {
#  type        = number
#  description = "Duration in days after which the key is deleted after destruction of the resource"
#  default     = 10
#}
#
#variable "enable_key_rotation" {
#  type        = bool
#  description = "Specifies whether key rotation is enabled"
#  default     = true
#}
#
#variable "alias" {
#  type        = string
#  description = "The display name of the alias. The name must start with the word `alias` followed by a forward slash. If not specified, the alias name will be auto-generated."
#  default     = ""
#}
#
#variable "key_usage" {
#  type        = string
#  description = "Specifies the intended use of the key. Valid values: `ENCRYPT_DECRYPT` or `SIGN_VERIFY`."
#  default     = "ENCRYPT_DECRYPT"
#}
#
#variable "customer_master_key_spec" {
#  type        = string
#  description = "Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: `SYMMETRIC_DEFAULT`, `RSA_2048`, `RSA_3072`, `RSA_4096`, `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521`, or `ECC_SECG_P256K1`."
#  default     = "SYMMETRIC_DEFAULT"
#}
#
## Central logs subscription filter
#variable "CENTRAL_LOGS_ENABLE" {
#  type        = bool
#  description = "Enable sending the logs to the central OpenSearch cluster. Subscription filter creation depends on this."
#  default     = false
#}
#
#variable "CENTRAL_LOGS_OPENSEARCH_ARN" {
#  type        = string
#  description = "The domain ARN of the central OpenSearch domain"
#  default     = "arn:aws:es:eu-west-1:700764737355:domain/central-logs-prod"
#}
#
#variable "CENTRAL_LOGS_OPENSEARCH_ENDPOINT" {
#  type        = string
#  description = "The domain endpoint of the central OpenSearch domain"
#  default     = "search-central-logs-prod-6lf6xwewya6zn76xzipbk4tesy.eu-west-1.es.amazonaws.com"
#}
#
#variable "CENTRAL_LOGS_ENABLE_PROXY_ISSUER" {
#  type        = bool
#  description = "Enable log forwarding to the central logs OpenSearch for proxy-issuer"
#  default     = false
#}
#
#variable "CENTRAL_LOGS_ENABLE_ISSUER_DIRECTORY" {
#  type        = bool
#  description = "Enable log forwarding to the central logs OpenSearch for issuer-directory"
#  default     = false
#}
#
#variable "CENTRAL_LOGS_ENABLE_SSI_API" {
#  type        = bool
#  description = "Enable log forwarding to the central logs OpenSearch for ssi-api"
#  default     = false
#}
#
#variable "CENTRAL_LOGS_ACCOUNT_ID" {
#  type        = string
#  description = "Account ID of the central logs account that contains the OpenSearch domain"
#  default     = "700764737355"
#}
#
#variable "CENTRAL_LOGS_DOMAIN_NAME" {
#  type        = string
#  description = "Name of the central logs OpenSearch domain"
#  default     = "central-logs-prod"
#}
#
#

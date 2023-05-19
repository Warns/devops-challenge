############### FACEIT-GENERIC ###############
variable "enable_faceit_app" {
  type        = bool
  description = "Enable/Disable faceit app"
}

variable "faceit_cidr_block" {
  type        = string
  description = "Faceit CIDR block"
}

variable "faceit_container_image" {
  type        = string
  description = "The default container image to use in container definition"
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
      "wget  -t1 -nv -O /dev/null -q 'http://localhost:8080/health' || exit 1"
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
  description = "The path of the faceit healthcheck which the ALB checks"
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

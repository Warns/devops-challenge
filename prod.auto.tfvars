enabled           = true
namespace         = "faceit"
top_level_domain  = "challenge-task.link."
enable_faceit_app = true

vpc_cidr_block = "172.16.0.0/16"

faceit_cidr_block = "172.16.128.0/21"

rds_postgres_cidr_block = "172.16.3.0/24"

faceit_container_image = "093013615152.dkr.ecr.eu-west-1.amazonaws.com/faceit-app:1.0.0"

faceit_parameter_write = [
  {
    name      = "PARAMETER"
    value     = "CUSTOM_VALUE"
    type      = "String"
    overwrite = "true"
  }
]
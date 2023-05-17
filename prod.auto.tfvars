enabled           = true
namespace         = "faceit"
environment       = "prod"
name              = "challenge"
delimiter         = "-"
top_level_domain  = "challenge-task.nl."
enable_faceit_app = true

faceit_cidr_block = "172.16.128.0/21"

rds_postgres_cidr_block = "172.16.3.0/24"

faceit_parameter_write = [
  {
    name      = "CGO_ENABLED"
    value     = "0"
    type      = "String"
    overwrite = "true"
  },
  {
    name      = "GOOS"
    value     = "linux"
    type      = "String"
    overwrite = "true"
  },
  {
    name      = "GOARCH"
    value     = "amd64"
    type      = "String"
    overwrite = "true"
  }
]
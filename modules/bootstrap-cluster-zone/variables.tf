variable "zone_name" {
  type        = string
  default     = "$$${name}.$$${stage}.$$${parent_zone_name}"
  description = "Zone name"
}
variable "zone_name" {
  type        = string
  default     = "$$${name}.$$${stage}.$$${parent_zone_name}"
  description = "Zone name"
}

variable "parent_zone_id" {
  type        = string
  default     = ""
  description = "ID of the hosted zone to contain this record  (or specify `parent_zone_name`)"
}

variable "parent_zone_name" {
  type        = string
  default     = ""
  description = "Name of the hosted zone to contain this record (or specify `parent_zone_id`)"
}

variable "parent_zone_record_enabled" {
  type        = bool
  default     = true
  description = "Whether to create the NS record on the parent zone. Useful for creating a cluster zone across accounts. `var.parent_zone_name` required if set to false."
}

variable "private_zone_enabled" {
  type        = bool
  default     = false
  description = "Whether to create zone as Private. vpc_id must be set if this is true. parent_zone_record_enabled must be false. parent_zone_name must be 'private' "
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Private zone VPC id to attach to this zone"
}

variable "acl" {
  type        = string
  description = "Canned ACL to apply to the S3 bucket"
  default     = "log-delivery-write"
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "Bucket name. If provided, the bucket will be created with this name instead of generating the name from the context"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = <<-EOT
    When `true`, permits a non-empty S3 bucket to be deleted by first deleting all objects in the bucket.
    THESE OBJECTS ARE NOT RECOVERABLE even if they were versioned and stored in Glacier.
    Must be set `false` unless `force_destroy_enabled` is also `true`.
    EOT
}

variable "access_log_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where S3 access logs will be sent to"
  default     = ""
}

variable "access_log_bucket_prefix" {
  type        = string
  description = "Prefix to prepend to the current S3 bucket name, where S3 access logs will be sent to"
  default     = null
}

variable "allow_ssl_requests_only" {
  type        = bool
  description = "Require requests to use Secure Socket Layer (HTTPS/SSL)."
  default     = true
}

variable "versioning_enabled" {
  type        = bool
  description = "Enable object versioning, keeping multiple variants of an object in the same bucket"
  default     = true
}

variable "lifecycle_configuration_rules" {
  type = list(object({
    enabled = bool
    id      = string

    abort_incomplete_multipart_upload_days = number

    # `filter_and` is the `and` configuration block inside the `filter` configuration.
    # This is the only place you should specify a prefix.
    filter_and = any
    expiration = any
    transition = list(any)

    noncurrent_version_expiration = any
    noncurrent_version_transition = list(any)
  }))
  default     = []
  description = <<-EOT
    A list of S3 bucket v2 lifecycle rules, as specified in [terraform-aws-s3-bucket](https://github.com/cloudposse/terraform-aws-s3-bucket)"
    These rules are not affected by the deprecated `lifecycle_rule_enabled` flag.
    **NOTE:** Unless you also set `lifecycle_rule_enabled = false` you will also get the default deprecated rules set on your bucket.
    EOT
}

variable "lifecycle_rule_enabled" {
  type        = bool
  description = "Enable lifecycle events on this bucket"
  default     = true
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 90
  description = "Specifies when noncurrent object versions expire"
}

variable "noncurrent_version_transition_days" {
  type        = number
  default     = 30
  description = "Specifies when noncurrent object versions transitions"
}

variable "standard_transition_days" {
  type        = number
  default     = 30
  description = "Number of days to persist in the standard storage tier before moving to the infrequent access tier"
}

variable "enable_glacier_transition" {
  type        = bool
  default     = true
  description = "Enables the transition to AWS Glacier which can cause unnecessary costs for huge amount of small files"
}

variable "expiration_days" {
  type        = number
  default     = 90
  description = "Number of days after which to expunge the objects"
}

variable "glacier_transition_days" {
  type        = number
  default     = 60
  description = "Number of days after which to move the data to the glacier storage tier"
}

variable "lifecycle_prefix" {
  type        = string
  description = "Prefix filter. Used to manage object lifecycle events"
  default     = ""
}
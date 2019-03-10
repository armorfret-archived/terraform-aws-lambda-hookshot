variable "version" {
  description = "Version of the Lambda to use"
  type        = "string"
  default     = "v0.3.1"
}

variable "logging_bucket" {
  description = "S3 bucket to use for bucket logging"
  type        = "string"
}

variable "config_bucket" {
  description = "S3 bucket to use for configuration files"
  type        = "string"
}

variable "lambda_bucket" {
  description = "S3 bucket from which to read Lambda ZIP"
  type        = "string"
}

variable "rate" {
  description = "Frequency at which to run the Lambda"
  type        = "string"
  default     = "1 hour"
}

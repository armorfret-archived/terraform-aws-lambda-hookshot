variable "logging-bucket" {
  type = "string"
}

variable "data-bucket" {
  type = "string"
}

variable "lambda-bucket" {
  type    = "string"
  default = "akerl-hookshot"
}

variable "rate" {
  type    = "string"
  default = "1 hour"
}

module "lambda" {
  lambda-bucket  = "${var.lambda-bucket}"
  lambda-version = "${chomp(file("${path.module}/version"))}"
  function-name  = "hookshot_${var.data-bucket}"

  environment-variables = {
    S3_BUCKET = "${var.data-bucket}"
    S3_KEY    = "config/urls"
  }

  access-policy-document = "${data.aws_iam_policy_document.lambda_perms.json}"
  trust-policy-document  = "${data.aws_iam_policy_document.lambda_assume.json}"
}

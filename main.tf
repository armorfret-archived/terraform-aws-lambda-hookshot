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

  source-type = ["events"]
  source-arn  = ["${aws_cloudwatch_event_rule.cron.arn}"]
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "hookshot_${var.data-bucket}_cron"
  description         = "Launch lambda"
  schedule_expression = "rate(${var.rate})"
}

resource "aws_cloudwatch_event_target" "cron" {
  rule      = "${aws_cloudwatch_event_rule.cron.name}"
  target_id = "invoke_hookshot"
  arn       = "${aws_lambda_function.lambda.arn}"
}

module "publish-user" {
  source         = "github.com/akerl/terraform-aws-s3-publish"
  logging-bucket = "${var.logging-bucket}"
  publish-bucket = "${var.data-bucket}"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_perms" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.data-bucket}/*",
      "arn:aws:s3:::${var.data-bucket}",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

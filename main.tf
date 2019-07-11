module "lambda" {
  source  = "armorfret/lambda/aws"
  version = "0.0.2"

  source_bucket  = "${var.lambda_bucket}"
  source_version = "${var.lambda_version}"
  function_name  = "hookshot_${var.config_bucket}"

  environment_variables = {
    S3_BUCKET = "${var.config_bucket}"
    S3_KEY    = "config.yaml"
  }

  access_policy_document = "${data.aws_iam_policy_document.lambda_perms.json}"

  source_types = ["events"]
  source_arns  = ["${aws_cloudwatch_event_rule.cron.arn}"]
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "hookshot_${var.config_bucket}_cron"
  description         = "Launch lambda"
  schedule_expression = "rate(${var.rate})"
}

resource "aws_cloudwatch_event_target" "cron" {
  rule      = "${aws_cloudwatch_event_rule.cron.name}"
  target_id = "invoke_hookshot"
  arn       = "${module.lambda.arn}"
}

module "publish-user" {
  source         = "armorfret/s3-publish/aws"
  version        = "0.0.2"
  logging_bucket = "${var.logging_bucket}"
  publish_bucket = "${var.config_bucket}"
}

data "aws_iam_policy_document" "lambda_perms" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.config_bucket}/*",
      "arn:aws:s3:::${var.config_bucket}",
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

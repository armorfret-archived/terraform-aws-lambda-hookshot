module "lambda" {
  source  = "armorfret/lambda/aws"
  version = "0.0.2"

  lambda-bucket  = "${var.lambda_bucket}"
  lambda-version = "${var.version}"
  function-name  = "hookshot_${var.config_bucket}"

  environment-variables = {
    S3_BUCKET = "${var.config_bucket}"
    S3_KEY    = "config/urls"
  }

  access-policy-document = "${data.aws_iam_policy_document.lambda_perms.json}"

  source-types = ["events"]
  source-arns  = ["${aws_cloudwatch_event_rule.cron.arn}"]
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

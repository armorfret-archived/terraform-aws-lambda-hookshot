module "lambda" {
  source  = "armorfret/lambda/aws"
  version = "0.0.1"

  lambda-bucket  = "${var.lambda-bucket}"
  lambda-version = "${var.version}"
  function-name  = "hookshot_${var.data-bucket}"

  environment-variables = {
    S3_BUCKET = "${var.data-bucket}"
    S3_KEY    = "config/urls"
  }

  access-policy-document = "${data.aws_iam_policy_document.lambda_perms.json}"
  trust-policy-document  = "${data.aws_iam_policy_document.lambda_assume.json}"

  source-types = ["events"]
  source-arns  = ["${aws_cloudwatch_event_rule.cron.arn}"]
}

resource "aws_cloudwatch_event_rule" "cron" {
  name                = "hookshot_${var.data-bucket}_cron"
  description         = "Launch lambda"
  schedule_expression = "rate(${var.rate})"
}

resource "aws_cloudwatch_event_target" "cron" {
  rule      = "${aws_cloudwatch_event_rule.cron.name}"
  target_id = "invoke_hookshot"
  arn       = "${module.lambda.arn}"
}

module "publish-user" {
  source         = "armorfret/terraform-aws-s3-publish"
  version        = "0.0.1"
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

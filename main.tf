###############################################################################
# Cost Anomaly Detection
###############################################################################
locals {
  # Get the first expression and validate its type
  first_expression = try(var.threshold_expressions[0], {
    operator   = "and"
    conditions = []
  })

  # Ensure we're using the correct operator block based on the first expression
  is_and_operator = local.first_expression.operator == "and"

  # Resource naming
  monitor_name        = "${var.name}-monitor"
  subscription_name   = "${var.name}-subscription"
  sns_topic_name      = "${var.name}-topic"
  chatbot_role_name   = "${var.name}-chatbot-role"
  chatbot_policy_name = "${var.name}-chatbot-policy"
  chatbot_stack_name  = "${var.name}-chatbot"

  # Default tags
  default_tags = {
    ManagedBy = "terraform"
    Module    = "cost-anomaly-alert"
  }

  # Merge default tags with user provided tags
  tags = merge(local.default_tags, var.tags)
}

resource "aws_ce_anomaly_monitor" "monitor" {
  name              = local.monitor_name
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = local.tags
}

resource "aws_ce_anomaly_subscription" "subscription" {
  name      = local.subscription_name
  frequency = "IMMEDIATE"

  threshold_expression {
    # Create an 'and' block for each condition when using AND operator
    dynamic "and" {
      for_each = local.is_and_operator ? local.first_expression.conditions : []
      content {
        dimension {
          key           = and.value.key
          values        = and.value.values
          match_options = and.value.match_options
        }
      }
    }

    # Create an 'or' block for each condition when using OR operator
    dynamic "or" {
      for_each = !local.is_and_operator ? local.first_expression.conditions : []
      content {
        dimension {
          key           = or.value.key
          values        = or.value.values
          match_options = or.value.match_options
        }
      }
    }
  }

  monitor_arn_list = [aws_ce_anomaly_monitor.monitor.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly.arn
  }

  tags = local.tags
}

###############################################################################
# SNS Topic
###############################################################################
resource "aws_sns_topic" "cost_anomaly" {
  name = local.sns_topic_name

  tags = local.tags
}

data "aws_iam_policy_document" "sns_policy" {
  statement {
    effect    = "Allow"
    resources = [aws_sns_topic.cost_anomaly.arn]
    actions   = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = [
        "costalerts.amazonaws.com",
      ]
    }
  }
}

resource "aws_sns_topic_policy" "cost_anomaly" {
  arn    = aws_sns_topic.cost_anomaly.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}

###############################################################################
# SNS Topic
###############################################################################

resource "aws_sns_topic_subscription" "email_subscription" {
  count = var.enable_email_subscription ? 1 : 0
  topic_arn = aws_sns_topic.cost_anomaly.arn
  protocol  = "email"
  endpoint  = var.email_address
}

###############################################################################
# Chatbot IAM
###############################################################################
data "aws_iam_policy_document" "cloudwatch_access" {
  count = var.enable_slack_integration ? 1 : 0

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
    ]
  }
}

resource "aws_iam_policy" "chatbot" {
  count = var.enable_slack_integration ? 1 : 0

  name        = local.chatbot_policy_name
  description = "AWS Chatbot policy for Cost Anomaly Detection"
  policy      = data.aws_iam_policy_document.cloudwatch_access[0].json

  tags = local.tags
}

data "aws_iam_policy_document" "chatbot_assume_role" {
  count = var.enable_slack_integration ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["chatbot.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chatbot" {
  count = var.enable_slack_integration ? 1 : 0

  name               = local.chatbot_role_name
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume_role[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  count = var.enable_slack_integration ? 1 : 0

  role       = aws_iam_role.chatbot[0].name
  policy_arn = aws_iam_policy.chatbot[0].arn
}

###############################################################################
# Slack Integration
###############################################################################
resource "aws_cloudformation_stack" "chatbot" {
  count = var.enable_slack_integration ? 1 : 0

  name = local.chatbot_stack_name

  template_body = yamlencode({
    Description = "AWS Chatbot Slack Integration for Cost Anomaly Detection"
    Resources = {
      AlertNotifications = {
        Type = "AWS::Chatbot::SlackChannelConfiguration"
        Properties = {
          ConfigurationName = "${var.name}-notifications"
          SlackWorkspaceId  = var.slack_workspace_id
          SlackChannelId    = var.slack_channel_id
          IamRoleArn        = aws_iam_role.chatbot[0].arn
          SnsTopicArns      = [aws_sns_topic.cost_anomaly.arn]
          GuardrailPolicies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
          LoggingLevel      = "INFO"
          UserRoleRequired  = false
        }
      }
    }
  })

  tags = local.tags
}

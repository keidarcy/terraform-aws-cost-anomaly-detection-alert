# AWS Cost Anomaly Detection Alert Terraform Module

This Terraform module creates AWS Cost Anomaly Detection resources with optional Slack integration via AWS Chatbot. It helps you monitor and get alerted for unexpected cost increases in your AWS account.

## Features

- Creates AWS Cost Anomaly Monitor for service-level monitoring
- Configures Anomaly Subscription with flexible threshold conditions
- Sets up SNS topic and required policies for notifications
- Optional Slack integration via AWS Chatbot
- Consistent resource naming and tagging

## Usage

### Basic Usage with AND Conditions

```hcl
module "cost_anomaly_alert" {
  source = "path/to/module"

  name = "sre-cost-anomaly"

  threshold_expressions = [
    {
      operator = "and"
      conditions = [
        {
          key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
          values        = ["10"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        },
        {
          key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
          values        = ["100"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        }
      ]
    }
  ]

  tags = {
    Environment = "Production"
  }
}
```

### With Slack Integration

```hcl
module "cost_anomaly_alert" {
  source = "path/to/module"

  name = "sre-cost-anomaly"

  threshold_expressions = [
    {
      operator = "and"
      conditions = [
        {
          key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
          values        = ["10"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        },
        {
          key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
          values        = ["100"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        }
      ]
    }
  ]

  # Enable Slack integration
  enable_slack_integration = true
  slack_workspace_id       = "TXXXXXXXX"
  slack_channel_id        = "CXXXXXXXX"

  tags = {
    Environment = "Production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |

## Resources Created

This module creates the following resources:

- AWS Cost Explorer Anomaly Monitor
- AWS Cost Explorer Anomaly Subscription
- SNS Topic with required policies
- AWS Chatbot configuration (optional)
- IAM roles and policies for AWS Chatbot (when Slack integration is enabled)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Base name for all resources | `string` | `"cost-anomaly"` | no |
| threshold_expressions | List of threshold expressions | `list(object)` | See variables.tf | no |
| enable_slack_integration | Enable Slack integration | `bool` | `false` | no |
| slack_workspace_id | Slack Workspace ID | `string` | `""` | no |
| slack_channel_id | Slack Channel ID | `string` | `""` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| monitor_id | ID of the Cost Anomaly Monitor |
| subscription_id | ID of the Cost Anomaly Subscription |
| sns_topic_arn | ARN of the SNS topic |
| chatbot_role_arn | ARN of the Chatbot IAM role |

## Resource Naming

The module creates resources with the following naming pattern:

- Monitor: `{name}-monitor`
- Subscription: `{name}-subscription`
- SNS Topic: `{name}-topic`
- Chatbot Role: `{name}-chatbot-role`
- Chatbot Policy: `{name}-chatbot-policy`
- Chatbot Stack: `{name}-chatbot`

## Tags

All resources are tagged with:
- Default tags:
  - `ManagedBy`: "terraform"
  - `Module`: "cost-anomaly-alert"
- User-provided tags (merged with defaults)

## Notes

1. The module supports either AND or OR conditions, but not both simultaneously
2. Each expression can have up to 2 conditions
3. Slack integration requires valid Workspace and Channel IDs
4. All resource names must follow AWS naming restrictions

## Authors

Module is maintained by [Your Name/Organization]

## License

Apache 2 Licensed. See LICENSE for full details.

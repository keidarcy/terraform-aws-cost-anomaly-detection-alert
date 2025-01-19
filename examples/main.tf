
###############################################################################
# Terraform Configuration
###############################################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

###############################################################################
# Variables
###############################################################################
variable "slack_workspace_id" {
  description = "Slack Workspace ID for cost anomaly notifications"
  type        = string
  default     = "AAAA"
}

variable "slack_channel_id" {
  description = "Slack Channel ID for cost anomaly notifications"
  type        = string
  default     = "BBBB"
}


###############################################################################
# Cost Anomaly Detection
###############################################################################
module "cost_anomaly_detection" {
  source = "../"

  name = "happy-reduce-cost"

  threshold_expressions = [
    {
      # operator = "or"
      operator = "and"
      conditions = [
        {
          key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
          values        = ["10"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        },
        {
          key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
          values        = ["10"]
          match_options = ["GREATER_THAN_OR_EQUAL"]
        }
      ]
    }
  ]

  # Slack integration
  enable_slack_integration = true
  slack_workspace_id       = var.slack_workspace_id
  slack_channel_id         = var.slack_channel_id

  tags = {
    Environment = "Staging"
    Managed_by  = "Terraform"
  }
}

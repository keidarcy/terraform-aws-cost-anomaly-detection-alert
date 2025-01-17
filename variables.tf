variable "name" {
  description = "Base name for all resources. Will be prefixed/suffixed according to AWS naming requirements."
  type        = string
  default     = "cost-anomaly"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Name must only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "threshold_expressions" {
  description = "List of threshold expressions. Each expression must use either 'and' or 'or' operator with its conditions."
  type = list(object({
    operator = string # "and" or "or"
    conditions = list(object({
      key           = string
      values        = list(string)
      match_options = list(string)
    }))
  }))
  default = [
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

  validation {
    condition = alltrue([
      for expr in var.threshold_expressions :
      contains(["and", "or"], expr.operator) &&
      length(expr.conditions) > 0 &&
      length(expr.conditions) <= 2
    ])
    error_message = "Each expression must use either 'and' or 'or' operator and have 1 or 2 conditions."
  }
}

variable "enable_slack_integration" {
  description = "Whether to enable Slack integration via AWS Chatbot"
  type        = bool
  default     = false
}

variable "enable_email_subscription" {
  description = "Whether to enable SNS Email integration"
  type        = bool
  default     = false
}

variable "slack_workspace_id" {
  description = "ID of the Slack workspace for AWS Chatbot integration"
  type        = string
  default     = ""
}

variable "slack_channel_id" {
  description = "ID of the Slack channel for AWS Chatbot integration"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "email_address" {
  description = "Email Address for the SNS subscription"
  type        = string
  default     = ""
}

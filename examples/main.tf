###############################################################################
# Cost Anomaly Detection
###############################################################################
module "cost_anomaly_detection" {
  source = "../"

  name = "happy-reduce-cost"

  threshold_expressions = [
    {
      operator = "or"
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

  # Slack integration
  enable_slack_integration = true
  slack_workspace_id       = "AAAA"
  slack_channel_id         = "BBBB"

  tags = {
    Environment = "Staging"
    Managed_by  = "Terraform"
  }
}

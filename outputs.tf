output "monitor_id" {
  description = "ID of the Cost Anomaly Monitor"
  value       = aws_ce_anomaly_monitor.monitor.id
}

output "subscription_id" {
  description = "ID of the Cost Anomaly Subscription"
  value       = aws_ce_anomaly_subscription.subscription.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.cost_anomaly.arn
}

output "chatbot_role_arn" {
  description = "ARN of the Chatbot IAM role"
  value       = try(aws_iam_role.chatbot[0].arn, null)
} 

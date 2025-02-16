output "workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "prometheus_workspace_id" {
  value = azurerm_monitor_workspace.prometheus.id
}

output "prometheus_dcr_id" {
  description = "The ID of the Prometheus Data Collection Rule"
  value       = azurerm_monitor_data_collection_rule.prometheus.id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}
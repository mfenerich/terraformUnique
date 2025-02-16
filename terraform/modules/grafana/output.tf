output "grafana_endpoint" {
  value       = azurerm_dashboard_grafana.this.endpoint
  description = "The endpoint URL for Azure Managed Grafana"
}

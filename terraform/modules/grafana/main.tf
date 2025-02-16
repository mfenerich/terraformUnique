# Deploy Azure Managed Grafana
resource "azurerm_dashboard_grafana" "this" {
  name                              = "grafana-${var.environment}"
  resource_group_name               = var.resource_group_name
  location                          = var.location
  grafana_major_version             = 10
  api_key_enabled                   = false  # No API key needed
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = var.monitor_workspace_id
  }

  tags = merge(var.tags, { environment = var.environment })
}

# Since the access to Azure Managed Grafana is public, we need to assign the "Grafana Admin" role to the current user
resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.this.id
  role_definition_name = "Grafana Admin"
  # principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
  principal_id         = "f1640552-081b-47d6-bd1d-b4ffa43b4c9e" # For desmonstrations purpose
}


resource "azurerm_role_assignment" "grafana_subscription_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}


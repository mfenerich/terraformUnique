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
resource "null_resource" "grafana_role_assignment" {
  depends_on = [azurerm_dashboard_grafana.this]

  provisioner "local-exec" {
    command = <<EOT
      az role assignment create \
        --assignee $(az ad signed-in-user show --query id -o tsv) \
        --role "Grafana Admin" \
        --scope ${azurerm_dashboard_grafana.this.id}
    EOT
  }
}

resource "azurerm_role_assignment" "grafana_subscription_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}


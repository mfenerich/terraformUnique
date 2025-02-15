# Create Log Analytics Workspace (For AKS Monitoring)
resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-aks-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.tags, { environment = var.environment })
}

# Enable Azure Monitor for Containers (Kubernetes Insights)
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.this.location
  resource_group_name   = azurerm_log_analytics_workspace.this.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Enable Azure Managed Prometheus
resource "azurerm_monitor_workspace" "prometheus" {
  name                = "prometheus-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                = "prometheus-dcr-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    monitor_account {
      name               = "monitorAccount"
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
    }
  }
  
  # Add data sources for Prometheus metrics
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["monitorAccount"]
  }
}

resource "azurerm_role_assignment" "aks_prometheus" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = var.aks_identity_principal_id
}

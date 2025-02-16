resource "azurerm_kubernetes_cluster" "this" {
  name                = "huggingface-aks-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "huggingfaceaks"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = "system"
    vm_size                      = "Standard_B2s"
    vnet_subnet_id               = var.aks_subnet_id
    os_disk_size_gb              = 128
    type                         = "VirtualMachineScaleSets"
    orchestrator_version         = var.kubernetes_version
    only_critical_addons_enabled = true
    auto_scaling_enabled         = true
    min_count = var.environment == "prod" ? 3 : 1
    max_count = var.environment == "prod" ? 5 : 1
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    service_cidr      = "10.0.3.0/24"
    dns_service_ip    = "10.0.3.10"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  auto_scaler_profile {
    scale_down_delay_after_add = "10m"
    scale_down_unneeded        = "10m"
    balance_similar_node_groups = true
    expander                   = "random"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2]
    }
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  azure_policy_enabled = true

  tags = merge(var.tags, { environment = var.environment })
}

resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = "Standard_A8m_v2"
  os_disk_size_gb       = 128
  auto_scaling_enabled  = true
  min_count             = var.environment == "prod" ? 1 : 1
  max_count             = var.environment == "prod" ? 5 : 1
  vnet_subnet_id        = var.aks_subnet_id
  node_labels = {
    "agentpool" = "userpool"
  }
}

# Enable Azure Monitor Prometheus metrics collection
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  name                          = "prometheus-dce-${var.environment}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  kind                        = "Linux"
}

# Associate the data collection rule with AKS cluster
resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  name                    = "prometheus-dcra-${var.environment}"
  target_resource_id     = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = var.prometheus_dcr_id # Pass DCR ID from log_analytics module
  description            = "Association between AKS cluster and Prometheus DCR"
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

##############################
# Generate unique sufix
##############################

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

##############################
# Resource Groups
##############################

resource "azurerm_resource_group" "huggingface_dev" {
  count    = var.environment == "dev" ? 1 : 0
  name     = "huggingface-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { environment = "dev" })
}

resource "azurerm_resource_group" "huggingface_prod" {
  count    = var.environment == "prod" ? 1 : 0
  name     = "huggingface-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { environment = "prod" })

  lifecycle {
    prevent_destroy = true
  }
}

##############################
# Virtual Network & Subnets
##############################

resource "azurerm_virtual_network" "aks_cosmos_vnet" {
  name                = "aks-cosmos-vnet-${var.environment}-${random_string.suffix.result}"
  location            = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].location : azurerm_resource_group.huggingface_prod[0].location
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  address_space       = ["10.0.0.0/16"]
  tags                = merge(var.tags, { environment = var.environment })
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet-${var.environment}-${random_string.suffix.result}"
  resource_group_name  = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

resource "azurerm_subnet" "cosmosdb_subnet" {
  name                 = "cosmosdb-subnet-${var.environment}-${random_string.suffix.result}"
  resource_group_name  = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

##############################
# Cosmos DB Account
##############################

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmosdb-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_virtual_network.aks_cosmos_vnet.location
  resource_group_name = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"
  public_network_access_enabled = false

  free_tier_enabled          = var.environment == "dev"
  automatic_failover_enabled = var.environment == "prod"

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    name = "EnableMongo"
  }

  mongo_server_version = "7.0" # TODO: Create a variable for the version

  // Add backup configuration only for production
  dynamic "backup" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      type                = "Periodic"
      interval_in_minutes = 1440  # 24h
      retention_in_hours  = 720   # 30d
    }
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = var.environment == "prod" ? [var.secondary_location] : []
    content {
      location          = geo_location.value
      failover_priority = 1
    }
  }

  tags = merge(var.tags, { environment = var.environment })
}

##############################
# Private DNS Zone & Virtual Network Link
##############################

resource "azurerm_private_dns_zone" "cosmosdb_dns" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb_dns_vnet_link" {
  name                  = "cosmosdb-dns-vnet-link-${var.environment}-${random_string.suffix.result}"
  resource_group_name   = azurerm_private_dns_zone.cosmosdb_dns.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_dns.name
  virtual_network_id    = azurerm_virtual_network.aks_cosmos_vnet.id
}

##############################
# Private Endpoint for Cosmos DB
##############################

resource "azurerm_private_endpoint" "cosmosdb_private_endpoint" {
  name                = "pe-cosmosdb-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_virtual_network.aks_cosmos_vnet.location
  resource_group_name = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  subnet_id           = azurerm_subnet.cosmosdb_subnet.id

  private_service_connection {
    name                           = "cosmosdb-connection-${random_string.suffix.result}"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group-${var.environment}-${random_string.suffix.result}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_dns.id]
  }
}

##############################
# AKS Cluster
##############################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "huggingface-aks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_virtual_network.aks_cosmos_vnet.location
  resource_group_name = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  dns_prefix          = "huggingfaceaks"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = "system"
    vm_size                      = "Standard_DS2_v2"
    vnet_subnet_id               = azurerm_subnet.aks_subnet.id
    os_disk_size_gb              = 128
    type                         = "VirtualMachineScaleSets"
    orchestrator_version         = var.kubernetes_version
    only_critical_addons_enabled = true

    # Enable the cluster autoscaler using the correct attribute
    auto_scaling_enabled = true

    # Set the minimum and maximum node counts
    min_count = var.environment == "prod" ? 3 : 1
    max_count = var.environment == "prod" ? 5 : 3
  }


  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.0.3.0/24"
    dns_service_ip     = "10.0.3.10"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
  }

  auto_scaler_profile {
    scale_down_delay_after_add = "10m"
    scale_down_unneeded        = "10m"
    balance_similar_node_groups = true  # Optional: Keeps node pools balanced
    expander                   = "random" # Optional: Controls how AKS scales
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2]
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  azure_policy_enabled = true

  tags = merge(var.tags, { environment = var.environment })
}



##############################
# Log Analytics Workspace
##############################

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-aks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_virtual_network.aks_cosmos_vnet.location
  resource_group_name = azurerm_virtual_network.aks_cosmos_vnet.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.tags, { environment = var.environment })
}

# Enable container insights solution
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "ContainerInsights"
  location             = azurerm_log_analytics_workspace.aks.location
  resource_group_name  = azurerm_log_analytics_workspace.aks.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.aks.id
  workspace_name       = azurerm_log_analytics_workspace.aks.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
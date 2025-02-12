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
  name                = "aks-cosmos-vnet-${var.environment}"
  location            = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].location : azurerm_resource_group.huggingface_prod[0].location
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  address_space       = ["10.0.0.0/16"]
  tags                = merge(var.tags, { environment = var.environment })
}

# Subnet for AKS (you might need a service endpoint for Cosmos DB if desired)
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet-${var.environment}"
  resource_group_name  = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

# Dedicated subnet for the Cosmos DB private endpoint
resource "azurerm_subnet" "cosmosdb_subnet" {
  name                 = "cosmosdb-subnet-${var.environment}"
  resource_group_name  = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  # No service endpoints are required here since we use Private Endpoints.
}

##############################
# Cosmos DB Account
##############################

resource "azurerm_cosmosdb_account" "main" {
  name                = "huggingface-cosmos-${var.environment}"
  location            = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].location : azurerm_resource_group.huggingface_prod[0].location
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  offer_type          = "Standard"
  kind                = "MongoDB"
  public_network_access_enabled = false

free_tier_enabled          = var.environment == "dev"
automatic_failover_enabled = var.environment == "prod"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  // MongoDB-specific configurations
  capabilities {
    name = "EnableMongo"
  }

  mongo_server_version = "7.0"

  // Add backup configuration only for production
  dynamic "backup" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      type                = "Periodic"
      interval_in_minutes = 1440  # 24 hours
      retention_in_hours  = 720   # 30 days
    }
  }

  // Primary region (matches the resource group's location)
  geo_location {
    location          = var.location
    failover_priority = 0
  }

  // Secondary region in production
  dynamic "geo_location" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      location          = "East US"
      failover_priority = 1
    }
  }

  tags = merge(var.tags, { environment = var.environment })
}

##############################
# Private DNS Zone & Virtual Network Link
##############################

# Create a private DNS zone for Cosmos DB's private endpoint.
resource "azurerm_private_dns_zone" "cosmosdb_dns" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
}

# Link the DNS zone to your VNet so that records resolve within it.
resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb_dns_vnet_link" {
  name                  = "cosmosdb-dns-vnet-link-${var.environment}"
  resource_group_name   = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_dns.name
  virtual_network_id    = azurerm_virtual_network.aks_cosmos_vnet.id
}

##############################
# Private Endpoint for Cosmos DB
##############################

resource "azurerm_private_endpoint" "cosmosdb_private_endpoint" {
  name                = "pe-cosmosdb-${var.environment}"
  location            = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].location : azurerm_resource_group.huggingface_prod[0].location
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  subnet_id           = azurerm_subnet.cosmosdb_subnet.id

  private_service_connection {
    name                           = "cosmosdb-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  # Nested block to configure DNS for the private endpoint.
  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group-${var.environment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_dns.id]
  }
}

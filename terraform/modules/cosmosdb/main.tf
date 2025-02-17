resource "azurerm_cosmosdb_account" "this" {
  name                          = "cosmosdb-${var.environment}-${var.suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  public_network_access_enabled = false

  free_tier_enabled          = var.environment == "dev" ? true : false
  automatic_failover_enabled = var.environment == "prod" ? true : false

  consistency_policy {
    consistency_level = "Session"
  }

  capabilities {
    name = "EnableMongo"
  }

  mongo_server_version = var.mongo_server_version

  dynamic "backup" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      type                = "Periodic"
      interval_in_minutes = 1440  # 24h backup interval
      retention_in_hours  = 720   # 30d retention
    }
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = var.environment == "prod" && var.secondary_location != "" ? [var.secondary_location] : []
    content {
      location          = geo_location.value
      failover_priority = 1
    }
  }

  tags = merge(var.tags, { environment = var.environment })
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "cosmosdb-dns-vnet-link-${var.environment}-${var.suffix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-cosmosdb-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.cosmosdb_subnet_id

  private_service_connection {
    name                           = "cosmosdb-connection-${var.suffix}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group-${var.environment}-${var.suffix}"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}

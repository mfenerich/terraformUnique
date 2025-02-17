resource "azurerm_virtual_network" "this" {
  name                = "aks-cosmos-vnet-${var.environment}-${var.suffix}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
  tags                = merge(var.tags, { environment = var.environment })
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet-${var.environment}-${var.suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

# resource "azurerm_subnet" "cosmosdb" {
#   name                 = "cosmosdb-subnet-${var.environment}-${var.suffix}"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.this.name
#   address_prefixes     = ["10.0.2.0/24"]
# }

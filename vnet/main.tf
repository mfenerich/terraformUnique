provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "huggingface" {
  name     = "huggingFace"
  location = "South India"
}

resource "azurerm_virtual_network" "aks_cosmos_vnet" {
  name                = "aks-cosmos-vnet"
  location            = azurerm_resource_group.huggingface.location
  resource_group_name = azurerm_resource_group.huggingface.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.huggingface.name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "cosmosdb_subnet" {
  name                 = "cosmosdb-subnet"
  resource_group_name  = azurerm_resource_group.huggingface.name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}


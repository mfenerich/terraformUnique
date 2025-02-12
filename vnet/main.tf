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

resource "azurerm_virtual_network" "aks_cosmos_vnet" {
  name                = "aks-cosmos-vnet-${var.environment}"
  location            = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].location : azurerm_resource_group.huggingface_prod[0].location
  resource_group_name = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  address_space       = ["10.0.0.0/16"]
  tags               = merge(var.tags, { environment = var.environment })
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet-${var.environment}"
  resource_group_name  = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "cosmosdb_subnet" {
  name                 = "cosmosdb-subnet-${var.environment}"
  resource_group_name  = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
  virtual_network_name = azurerm_virtual_network.aks_cosmos_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

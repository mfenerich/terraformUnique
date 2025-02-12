output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.environment == "dev" ? azurerm_resource_group.huggingface_dev[0].name : azurerm_resource_group.huggingface_prod[0].name
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.aks_cosmos_vnet.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "cosmosdb_subnet_id" {
  description = "The ID of the CosmosDB subnet"
  value       = azurerm_subnet.cosmosdb_subnet.id
}

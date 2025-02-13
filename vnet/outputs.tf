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

output "cosmosdb_endpoint" {
  description = "The endpoint of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_primary_key" {
  description = "The primary key for the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.tgi_storage.name
}

output "storage_account_key" {
  value = azurerm_storage_account.tgi_storage.primary_access_key
  sensitive = true
}

output "storage_share_name" {
  value = azurerm_storage_share.tgi_share.name
}

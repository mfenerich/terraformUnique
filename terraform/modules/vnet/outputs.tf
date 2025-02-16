output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "cosmosdb_subnet_id" {
  value = azurerm_subnet.cosmosdb.id
}

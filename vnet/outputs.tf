output "resource_group" {
  value = module.resource_group
}

output "virtual_network" {
  value = module.vnet
}

output "cosmosdb_account_id" {
  value = module.cosmosdb.cosmosdb_account_id
}

output "aks_cluster_kube_config" {
  value = module.aks.kube_config
  sensitive = true
}

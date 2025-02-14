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

output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_admin_username" {
  value = module.acr.admin_username
}

output "acr_admin_password" {
  value     = module.acr.admin_password
  sensitive = true
}

output "acr_name" {
  value = module.acr.name
}
output "kube_config" {
  value = azurerm_kubernetes_cluster.this.kube_config[0]
}

output "kubelet_identity_object_id" {
  description = "The Object ID of the AKS Managed Identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "cluster_id" {
  description = "The Azure Resource ID of the AKS Cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_identity_principal_id" {
  value = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
output "kube_config" {
  value = azurerm_kubernetes_cluster.this.kube_config[0]
}

output "kubelet_identity_object_id" {
  description = "The Object ID of the AKS Managed Identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
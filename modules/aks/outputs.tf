output "kube_config" {
  value = azurerm_kubernetes_cluster.this.kube_config[0]
}

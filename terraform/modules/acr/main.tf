resource "azurerm_container_registry" "this" {
  name                = "${var.environment}acr${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = merge(var.tags, { environment = var.environment })
}

resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = var.aks_kubelet_identity_object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
  skip_service_principal_aad_check = false
}

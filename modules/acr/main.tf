resource "azurerm_container_registry" "this" {
  name                = "${var.environment}acr${var.suffix}" # TODO: Change to acr-${var.environment}-${var.suffix}
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = merge(var.tags, { environment = var.environment })
}
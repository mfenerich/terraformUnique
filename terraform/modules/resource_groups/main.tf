resource "azurerm_resource_group" "this" {
  name     = "huggingface-${var.environment}"
  location = var.location
  tags     = merge(var.tags, { environment = var.environment })

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_storage_account" "this" {
  name                     = "tgistorage${var.suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(var.tags, { environment = var.environment })
}

resource "azurerm_storage_share" "this" {
  name               = "modeldata"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 50
}

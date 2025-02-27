output "login_server" {
  value = azurerm_container_registry.this.login_server
}

output "admin_username" {
  value = azurerm_container_registry.this.admin_username
}

output "admin_password" {
  value     = azurerm_container_registry.this.admin_password
  sensitive = true
}

output "name" {
  value = azurerm_container_registry.this.name
}
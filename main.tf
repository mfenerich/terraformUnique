terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.19"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Generate a unique suffix for naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

##############################
# Modules Invocation
##############################

# 1. Resource Group
module "resource_group" {
  source       = "./modules/resource_groups"
  environment  = var.environment
  location     = var.location
  tags         = var.tags
  prevent_destroy = var.environment == "prod" ? true : false
}

# 2. Virtual Network & Subnets
module "vnet" {
  source                  = "./modules/vnet"
  environment             = var.environment
  resource_group_name     = module.resource_group.name
  resource_group_location = module.resource_group.location
  tags                    = var.tags
  suffix                  = random_string.suffix.result
}

# 3. Cosmos DB Account & Private Endpoint/DNS
module "cosmosdb" {
  source                = "./modules/cosmosdb"
  environment           = var.environment
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  tags                  = var.tags
  suffix                = random_string.suffix.result
  virtual_network_id    = module.vnet.virtual_network_id
  cosmosdb_subnet_id    = module.vnet.cosmosdb_subnet_id
  mongo_server_version  = var.mongo_server_version
  secondary_location    = var.secondary_location
}

# 4. Log Analytics Workspace & Solution
module "log_analytics" {
  source              = "./modules/log_analytics"
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  suffix              = random_string.suffix.result
  aks_cluster_id      = module.aks.cluster_id
  aks_identity_principal_id = module.aks.cluster_identity_principal_id
}

# 5. AKS Cluster (with a secondary node pool)
module "aks" {
  source                      = "./modules/aks"
  environment                 = var.environment
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  tags                        = var.tags
  suffix                      = random_string.suffix.result
  aks_subnet_id               = module.vnet.aks_subnet_id
  kubernetes_version          = var.kubernetes_version
  log_analytics_workspace_id  = module.log_analytics.workspace_id
  prometheus_dcr_id           = module.log_analytics.prometheus_dcr_id
}

# 6. Storage Account & File Share
module "storage" {
  source              = "./modules/storage"
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  suffix              = random_string.suffix.result
}

# 7. Azure Container Registry (ACR)
module "acr" {
  source                        = "./modules/acr"
  environment                   = var.environment
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tags                          = var.tags
  suffix                        = random_string.suffix.result
  sku                           = var.acr_sku
  admin_enabled                 = var.acr_admin_enabled
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
}

# 8. Azure Managed Grafana (NEW!)
module "grafana" {
  source              = "./modules/grafana"
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  monitor_workspace_id = module.log_analytics.prometheus_workspace_id
  subscription_id = var.subscription_id
}

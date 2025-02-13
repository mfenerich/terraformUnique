terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
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

# 7. Kubernetes Secret for Azure File (using Kubernetes provider)
provider "kubernetes" {
  host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

module "k8s_secret" {
  source                     = "./modules/k8s_secret"
  namespace                  = "default"
  storage_account_name       = module.storage.storage_account_name
  storage_account_primary_key = module.storage.storage_account_primary_key
}

# 8. Configure Helm Provider Using AKS Kubeconfig
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

# 9. Helm Release for the TGI Chart
module "helm_release" {
  source                = "./modules/helm_release"
  release_name          = "tgi"
  namespace             = "default"
  chart_path            = "./tgi-helm"
  chart_version         = "3.1.0"
  image_repository      = "ghcr.io/huggingface/text-generation-inference"
  image_tag             = "3.1.0"
  service_type          = "LoadBalancer"
  resources_requests_cpu    = "2"
  resources_requests_memory = "4"
  resources_limits_cpu      = "4"
  resources_limits_memory   = "8Gi"
  model_id              = "TinyLlama/TinyLlama-1.1B-Chat-v1.0"
  depends_on            = [module.aks]  # Ensure AKS is created first
}

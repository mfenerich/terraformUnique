variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "allowed_regions" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["East US", "West US", "South India", "Central Europe"]
}

variable "location" {
  description = "Primary location"
  type        = string
  default     = "South India"
  
  validation {
    condition     = contains(var.allowed_regions, var.location)
    error_message = "Primary location must be a valid Azure region."
  }
}

variable "secondary_location" {
  description = "Secondary location for Cosmos DB (only for prod)"
  type        = string
  default     = "Central Europe"
  
  validation {
    condition     = contains(var.allowed_regions, var.secondary_location)
    error_message = "Secondary location must be a valid Azure region."
  }

  validation {
    condition     = var.secondary_location != var.location
    error_message = "Secondary location must be different from the primary location."
  }
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default = "1.31"
}

variable "mongo_server_version" {
  description = "Mongo server version for Cosmos DB"
  type        = string
  default     = "7.0"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "allowed_regions" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["East US", "West US", "South India", "Central Europe"]
}

variable "location" {
  description = "Azure primary region"
  type        = string
  default     = "South India"
  
  validation {
    condition     = contains(var.allowed_regions, var.location)
    error_message = "Primary location must be a valid Azure region."
  }
}

variable "secondary_location" {
  description = "Azure secondary region"
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
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "huggingface"
  }
}

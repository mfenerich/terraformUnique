variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "suffix" {
  type = string
}

variable "sku" {
  type = string
}

variable "admin_enabled" {
  type = string
}

variable "aks_kubelet_identity_object_id" {
  description = "The Object ID of the AKS Managed Identity"
  type        = string
}

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

variable "aks_cluster_id" {
  description = "ID of the AKS Cluster for monitoring"
  type        = string
}

variable "aks_identity_principal_id" {
  description = "Principal ID of AKS cluster identity"
  type        = string
}
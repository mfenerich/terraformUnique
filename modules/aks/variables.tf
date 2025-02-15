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

variable "aks_subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "prometheus_dcr_id" {
  description = "The ID of the Prometheus Data Collection Rule"
  type        = string
}
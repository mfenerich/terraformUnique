variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "monitor_workspace_id" {
  description = "Azure Monitor Workspace ID for Prometheus"
  type        = string
}

variable "tags" {
  type = map(string)
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

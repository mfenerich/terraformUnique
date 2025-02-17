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

variable "virtual_network_id" {
  type = string
}

variable "cosmosdb_subnet_id" {
  type = string
}

variable "mongo_server_version" {
  type = string
}

variable "secondary_location" {
  type    = string
  default = ""
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "azure-file-secret"
    namespace = var.namespace
  }

  data = {
    azurestorageaccountname = var.storage_account_name
    azurestorageaccountkey  = var.storage_account_primary_key
  }

  type = "Opaque"
}

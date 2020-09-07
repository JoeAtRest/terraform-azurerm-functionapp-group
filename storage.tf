resource "azurerm_storage_account" "function-storageaccount" {
  name                     = local.storage_account
  resource_group_name      = azurerm_resource_group.app-rg.name
  location                 = azurerm_resource_group.app-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "function_storagecontainer" {
  name                  = local.storage_container
  storage_account_name  = azurerm_storage_account.function-storageaccount.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function_storageblob" {
    for_each = { for functionapp in var.functionapps : functionapp.name => functionapp }

  name                   = each.value.zip_path
  storage_account_name   = azurerm_storage_account.function-storageaccount.name
  storage_container_name = azurerm_storage_container.function_storagecontainer.name
  type                   = "Block"
  source                 = each.value.zip_path
}

data "azurerm_storage_account_sas" "function_sas" {
  connection_string = azurerm_storage_account.function-storageaccount.primary_connection_string
  https_only        = false
  resource_types {
    service   = false
    container = false
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start  = "2018-03-21"
  expiry = "2028-03-21"
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}
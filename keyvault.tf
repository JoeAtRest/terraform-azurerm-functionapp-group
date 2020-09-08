# This creates a keyvault in the resource group specified in main.tf.
# Currently it provides only the deployment App Registration and the
# function app, created in functionapp.tf with permissions to the 
# secrets within the vault.
#
# That can easily, and should be, changed to give the dev's testers and
# business systems groups their natural rights in the vault
#
# The secrets are also added to the vault at creation time

data "azurerm_client_config" "current" {}

# Make a key vault
resource "azurerm_key_vault" "app_keyvault" {
  name                = local.app_key_vault
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = var.tags
}

# Give the pipeline account access
resource "azurerm_key_vault_access_policy" "app_keyvault_pipeline" {  
  key_vault_id = azurerm_key_vault.app_keyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "create",
    "get",
  ]

  secret_permissions = [
    "set",
    "get",
    "delete",
    "list"
  ]
}

# Give the function apps access
resource "azurerm_key_vault_access_policy" "app_keyvault_functionapps" {
  for_each = { for functionapp in var.functionapps : functionapp.name => functionapp }

  key_vault_id = azurerm_key_vault.app_keyvault.id

  tenant_id = azurerm_function_app.app_functionapp[each.value.name].identity[0].tenant_id
  object_id = azurerm_function_app.app_functionapp[each.value.name].identity[0].principal_id

  key_permissions = [    
    "get",
  ]

  secret_permissions = [    
    "get",    
  ]
}

# Give other things access
resource "azurerm_key_vault_access_policy" "app_keyvault_general" {
  for_each = { for access-policy in var.access-policies : access-policy.name => access-policy }

  key_vault_id = azurerm_key_vault.app_keyvault.id

  tenant_id = each.value.tenant_id
  object_id = each.value.object_id

  key_permissions = each.value.key_permissions
  secret_permissions = each.value.secret_permissions
}

# Load any secrets into the vault
resource "azurerm_key_vault_secret" "app_secret" {
  for_each = var.keyvault_secrets

  name          = each.key
  value         = each.value
  key_vault_id  = azurerm_key_vault.app_keyvault.id

  tags          = var.tags
}

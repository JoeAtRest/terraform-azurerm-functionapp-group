
# This is going to deploy a function app  to the resource group 
# specified in main.tf, the pipeline needs to supply a zip file
# containing the function app in the terraform working directory.
# 
# This function app is using secrets from a key vault created in
# keyvault.tf, the function app has managed identity which has
# been provided with get access to the key vault secrets

locals {
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" : "dotnet",
    "FUNCTIONS_EXTENSION_VERSION" : "~3",
    "APPINSIGHTS_INSTRUMENTATIONKEY" : azurerm_application_insights.rg.instrumentation_key       
  }    
}

# App Service Plan
resource "azurerm_app_service_plan" "app_app_service_plan" {
  name                = local.app_service_plan
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = var.tags
}

resource "azurerm_function_app" "app_functionapp" {
  for_each = { for functionapp in var.functionapps : functionapp.name => functionapp }

  name                      = "${var.subscription_prefix}-${var.location_prefix}-fa-${each.value.name}"
  location                  = azurerm_resource_group.app-rg.location
  resource_group_name       = azurerm_resource_group.app-rg.name
  app_service_plan_id       = azurerm_app_service_plan.app_app_service_plan.id
  storage_connection_string = azurerm_storage_account.function-storageaccount.primary_connection_string
  app_settings              = merge(
    each.value.settings,
    {"APPINSIGHTS_INSTRUMENTATIONKEY" : azurerm_application_insights.rg.instrumentation_key}, 
    {"WEBSITE_RUN_FROM_PACKAGE" : "https://${azurerm_storage_account.function-storageaccount.name}.blob.core.windows.net/${azurerm_storage_container.function_storagecontainer.name}/${azurerm_storage_blob.function_storageblob[each.value.name].name}${data.azurerm_storage_account_sas.function_sas.sas}"},    
    {"HASH" : filebase64sha256(each.value.zip_path) },
    zipmap(each.value.key_settings[*].name, [for s in each.value.key_settings[*].secret: "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.app_keyvault.vault_uri}secrets/${azurerm_key_vault_secret.app_secret[s].name}/${azurerm_key_vault_secret.app_secret[s].version})"]) 
    )
  version = "~3"
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
  
  site_config {
    dynamic "ip_restriction" {
      for_each = each.value.ip_restrictions
      
      content {
        ip_address  = "${ip_restriction.value}/32"        
      }
    }    
  }
}

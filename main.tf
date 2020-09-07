resource "random_id" "server" {
  keepers = {
    # Generate a new id each time we switch to a new Azure Resource Group
    rg_id = "${var.subscription_prefix}-${var.location_prefix}-rg-${var.app_name}"
  }

  byte_length = 8
}

locals {
  # This is a brilliant idea, by creating the names of everything as per the
  # the naming convention it is easier to deploy to further environments with
  # minimal changes, note that terraform has a random number generator which can
  # be used for things in Azure which need to be unique
  app_resource_group   = "${var.subscription_prefix}-${var.location_prefix}-rg-${var.app_name}"  
  storage_account      = "fastor${random_id.server.hex}"
  storage_container    = "function-apps"
  app_service_plan     = "${var.subscription_prefix}-${var.location_prefix}-app-${var.app_name}"
  app_key_vault        = "kvrg${random_id.server.hex}"
  app_insights         = "${var.subscription_prefix}-${var.location_prefix}-ai-${var.app_name}"  
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "app-rg" {
  name      = local.app_resource_group
  location  = var.location
  tags      = var.tags
}

output "instrumentationkey" {
  value = azurerm_application_insights.rg.instrumentation_key
}

output "functionappid" {
  value = zipmap(keys(azurerm_function_app.app_functionapp), values({for u in azurerm_function_app.app_functionapp: u.id => u.id}))
}
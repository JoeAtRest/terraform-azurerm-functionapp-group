resource "azurerm_application_insights" "rg" {
  name                = local.app_insights
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name
  application_type    = "web"
}
 provider "azurerm" {
  subscription_id = "196fbecd-860a-4c33-b19c-38977e9e395c"
  features {}
}
 
 
 resource "azurerm_resource_group" "azurerm_cognitive_account" {
  name     = "newca"
  location = "West Europe"
}

resource "azurerm_cognitive_account" "cognitive_services" {
  name                = "example-account"
  location            = azurerm_resource_group.azurerm_cognitive_account.location
  resource_group_name = azurerm_resource_group.azurerm_cognitive_account.name
  kind                = "Face"
  custom_subdomain_name = "face211"    
  sku_name = "S0"
  public_network_access_enabled = false
  tags = {
    Acceptance = "Test"
  }
}
data "azurerm_subnet" "newone" {
  name                 = "default"
  virtual_network_name = "newvnt1"
  resource_group_name  = "newca"
}
resource "azurerm_private_endpoint" "ca_primary" {
  name                = "exampleaccountpep"
  location            = azurerm_resource_group.azurerm_cognitive_account.location
  resource_group_name = azurerm_resource_group.azurerm_cognitive_account.name
  subnet_id           = data.azurerm_subnet.newone.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "azurerm_cognitive_account"
    private_connection_resource_id = azurerm_cognitive_account.cognitive_services.id
    subresource_names              = ["account"]
  }
}

# resource "azurerm_private_dns_a_record" "cognitive_services" {

#   provider            = azurerm.dns_zone
# #   for_each            = azurerm_private_endpoint.pe_primary
# #   name                = lookup(each.value, "custom_name", format("%s-%s-bus", local.default_name, each.key))
# #   zone_name           = local.private_dns_zone_name
# #   resource_group_name = local.private_dns_zone_resource_group_name
# #   ttl                 = 300

# #   records = [
# #     each.value.private_service_connection[0].private_ip_address
# #   ]
# # }
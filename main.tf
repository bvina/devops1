provider "azurerm" {
    subscription_id = "196fbecd-860a-4c33-b19c-38977e9e395c"
    features {}
}


module "rg-test" {
    source = "C:/Users/hemur/OneDrive/Desktop/tesr/rg-module-test/main_resources.tf1"
  resource_group_name = "rg"
  resource_group_location = "eastus"
}
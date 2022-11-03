
# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#       version = "3.8.0"
#     }
#   }
# }



resource "resource_group""rg" {
  name        = var.resource_group_name
  location    = var.resource_group_location
}
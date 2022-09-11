provider "corepipeline" {
}
provider "azurerm" {
}
provider "azurerm" {
  alias = "dns_zone_kv"
}
provider "azurerm" {
  alias = "dns_zone_database"
}

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

data "corepipeline_client_registry" "client_info" {}

#########################
# resource groups
#########################
data "azurerm_resource_group" "postresql_resource_group" {
  name     = var.leaf_resources.main_resource_group_name
}
#########################
# Networking & Subnets
#########################
data "azurerm_virtual_network" "postgresql_flexible_server_vnet" {
  name                = var.leaf_resources.virtual_network_name
  resource_group_name = var.leaf_resources.virtual_network_resource_group_name
}
data "azurerm_subnet" "postgresql_flexible_server_subnet" {
  name                 = var.leaf_resources.postgresql_subnet_name
  virtual_network_name = var.leaf_resources.virtual_network_name
  resource_group_name  = var.leaf_resources.virtual_network_resource_group_name
}
################################
# postgresql flexible server DNS
################################
data "azurerm_private_dns_zone" "postgresql_flexible_server_dns_zone" {
  name                = local.private_dns_zone_name
  resource_group_name = local.private_dns_zone_resource_group_name
}

#############################
# postgresql flexible server
#############################
resource "azurerm_postgresql_flexible_server" "postgresql_flexible_server" {
  name                = local.postgresql_server_name
  resource_group_name = data.azurerm_resource_group.postresql_resource_group.name
  location            = data.azurerm_resource_group.postresql_resource_group.location

  sku_name   = join("_", [lookup(local.tier_map, var.tier, "GeneralPurpose"), "Standard", var.size])
  storage_mb = var.storage_mb
  version    = var.postgresql_version

  zone = var.zone

  dynamic "high_availability" {
    for_each = var.standby_zone != null && var.tier != "Burstable" ? toset([var.standby_zone]) : toset([])

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = high_availability.value
    }
  }

  administrator_login    = var.admin.login
  administrator_password = var.admin.password

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? toset([var.maintenance_window]) : toset([])

    content {
      day_of_week  = lookup(maintenance_window.value, "day_of_week", 0)
      start_hour   = lookup(maintenance_window.value, "start_hour", 0)
      start_minute = lookup(maintenance_window.value, "start_minute", 0)
    }
  }

  private_dns_zone_id = data.azurerm_private_dns_zone.postgresql_flexible_server_dns_zone.id
  delegated_subnet_id = data.azurerm_subnet.postgresql_flexible_server_subnet.id

  tags = local.tags
}

######################################
# postgresql flexible server database
######################################

resource "azurerm_postgresql_flexible_server_database" "postgresql_flexible_db" {
  for_each = toset(var.databases_names)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  charset   = lookup(var.databases_charset, each.value, "UTF8")
  collation = lookup(var.databases_collation, each.value, "en_US.UTF8")
}

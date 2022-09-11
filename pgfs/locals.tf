resource "random_password" "password" {
  length      = 24
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "random_string" "unique-suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "string" {
  length  = 6
  special = false
  upper   = false
}

locals {
  # TODO: use common/regions submodule localterraform.com/SHARED/common/azurerm//modules/regions
  locations = {
    "canadacentral" = "cac"
    "canadaeast"    = "cae"
  }
  #location_short = local.locations[var.location]

  # Option to override in case of corepipeline provider doesnt populate these values
  service_tier   = var.service_tier == "" ? lower(data.corepipeline_client_registry.client_info.service_tier) : var.service_tier
  environment    = var.environment == "" ? lower(data.corepipeline_client_registry.client_info.environment) : var.environment
  portfolio      = var.portfolio == "" ? lower(data.corepipeline_client_registry.client_info.portfolio) : var.portfolio
  app_code       = var.app_code == "" ? lower(data.corepipeline_client_registry.client_info.app_code) : var.app_code
  app_name       = var.app_name == "" ? lower(data.corepipeline_client_registry.client_info.app_name) : var.app_name
  branch         = var.branch == "" ? (data.corepipeline_client_registry.client_info.branch) == "master" ? "" : data.corepipeline_client_registry.client_info.branch == null ? "" : lower(data.corepipeline_client_registry.client_info.branch)  : var.branch
  
  tier_map = {
    "GeneralPurpose"  = "GP"
    "Basic"           = "B"
    "MemoryOptimized" = "MO"
  }

  postgresql_server_name                  = (var.postgresql_server_name == "") ? join("-", [local.app_code, local.environment, random_string.string.result]) : var.postgresql_server_name

# PG Secrets
  secrets = [
    {
      name  = "admin-login"
      value       = (var.admin.login == "") ? "adminuser" : var.admin.login
      content_type = "PG Administrator login"
    },
    {
      name  = "admin-password"
      value       = (var.admin.password == "") ? random_password.password.result : var.admin.password
      content_type = "PG Administrator login password"
    }
  ]
  private_dns_zone_name                = "privatelink.database.windows.net"
  private_dns_zone_resource_group_name = "p-prod-ccoe-dnszones-dns-rg-glb-1"

  #pg_subnet_name = join("", ["postgresql", var.deployment_number])
   
  
  # Mandatory for compliance
  default_postgresql_configurations = {
    log_duration = "on"
    log_disconnections = "on"
  }
  postgresql_configurations = merge(local.default_postgresql_configurations, var.postgresql_configurations)

  tags = merge(var.tags, {
    AppCode            = local.app_code
    Component          = local.app_name
    Portfolio          = local.portfolio
    ServiceTier        = local.service_tier
    Environment        = local.environment
    DataClassification = var.data_classification
  } )

}

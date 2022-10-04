terraform {
  required_providers {
    azurerm = {
      version = "3.18.0"
      source  = "hashicorp/azurerm"
    }
    corepipeline = {
      version = "2.0.0"
      source  = "rbc.com/api/corepipeline"
    }
  }
}

provider "corepipeline" {}
data "corepipeline_client_registry" "client_info" {}

# azuread_client_config is used to access the deployment MSI Object ID
data "azuread_client_config" "current" {}

# Key Vault features are to allow deletion of the keyvault at the end of the Module testing.
provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = false
      purge_soft_delete_on_destroy    = false
      purge_soft_deleted_secrets_on_destroy = false
    }
  }
}

# Do not change dns_zone azure rm provider configuration.
provider "azurerm" {
  alias = "dns_zone"
  # p0004ss
  subscription_id            = "38ed9b78-9fa7-4981-80f4-dab76adfc854"
  skip_provider_registration = true
  features {}
}
provider "azurerm" {
  alias                      = "dns_zone_kv"
  subscription_id            = "38ed9b78-9fa7-4981-80f4-dab76adfc854"
  skip_provider_registration = true
  features {}
}
provider "azurerm" {
  alias                      = "dns_zone_database"
  subscription_id            = "1afac32f-5b7a-49c4-9c5d-da00161bbcae"
  skip_provider_registration = true
  features {}
}
# Do not change dns_zone azure rm provider configuration.

resource "random_string" "string" {
  length  = 6
  special = false
  upper   = false
}

locals {
  locations = {
    "canadacentral" = "cac"
    "canadaeast"    = "cae"
  }
  location = "canadacentral"
  location_short = local.locations[local.location]
  # Option to override in case of corepipeline provider doesnt populate these values
  service_tier   = lower(data.corepipeline_client_registry.client_info.service_tier)
  environment    = lower(data.corepipeline_client_registry.client_info.environment)
  portfolio      = lower(data.corepipeline_client_registry.client_info.portfolio)
  app_code       = lower(data.corepipeline_client_registry.client_info.app_code)
  app_name       = lower(data.corepipeline_client_registry.client_info.app_name)
  branch         = (data.corepipeline_client_registry.client_info.branch) == "master" ? "" : lower(data.corepipeline_client_registry.client_info.branch)
  deployment_number  = 1
  namespace          = "pg"
  data_classification = "internal"
  managed_identity_object_id    = "16e803ad-31a6-4a68-bbfb-a5b952055abf"

  pe_subnet_name = "pep"
  subnet_name    = "pgserver"

  tags = {
    service_tier  = "n"
    environment   = "qat"
    app_code      = "frm0-shared"
    app_name      = "terraform-azurerm-postgresql-flex"
    namespace     = "pg"
  }
  pg_server_name           = join("-", [local.app_code, local.environment, random_string.string.result])
  data_resource_group_name = join("-", [local.service_tier, local.environment, local.portfolio, local.app_code, local.app_name, local.namespace, "data-rg", module.azure_region.location_short, local.deployment_number])
  main_resource_group_name = join("-", [local.service_tier, local.environment, local.portfolio, local.app_code, local.app_name, local.namespace, "server", module.azure_region.location_short, local.deployment_number])

  #
  # Shared RG and VNET that should be used for testing
  #
  virtual_network_resource_group_name = "n-dev-ccoe-frm0-frm0-vnet-rg-cac-1"
  virtual_network_name                = "n-dev-ccoe-frm0-frm0-vnet-cac-1"

  # KeyVault & admin creds
  administrator_login    = "adminuser"
}

module "azure_region" {
  source  = "dev.canadacentral.tfe.nonp.c1.rbc.com/SHARED/common/azurerm//modules/regions"
  version = "0.2.4"
  azure_region = "can-central"
}

module "resource_group_server" {
  source  = "dev.canadacentral.tfe.nonp.c1.rbc.com/SHARED/common/azurerm//modules/resource_group"
  version = "0.2.4"
  providers = {
    azurerm      = azurerm
    corepipeline = corepipeline
  }
  namespace         = "server-flex"
  location          = module.azure_region.location_cli
  location_short    = module.azure_region.location_short
}

module "key_vault" {
  # Note: Ensure the source URI is set to the TFE instance URI you are using.
  # i.e source = uat.canadacentral.tfe.nonp.c1.rbc.com/SHARED/keyvault/azurerm
  source  = "dev.canadacentral.tfe.nonp.c1.rbc.com/SHARED/keyvault/azurerm"
  version = "1.0.18"
  providers = {
    azurerm          = azurerm
    azurerm.dns_zone = azurerm.dns_zone
    corepipeline     = corepipeline
  }
  depends_on = [
    module.resource_group_server
  ]
  resource_group_name                 = module.resource_group_server.resource_group_name
  virtual_network_resource_group_name = local.virtual_network_resource_group_name
  virtual_network_name                = local.virtual_network_name
  private_endpoint_subnet_name        = local.pe_subnet_name
  location                            = local.location

  user_access_policies                = [
      {
        user_object_id          = "670cacb9-1713-4960-8586-b6b91af58d82" # User Object ID
        secret_permissions      = ["List", "Set", "Get", "Delete"]
        key_permissions         = ["List", "Create"]
        certificate_permissions = ["List", "Create", "Import"]
      },
      {
        user_object_id          = "431a71c5-a37e-4596-9394-cc516ef14704" # AD Group Object ID
        secret_permissions      = ["List", "Set", "Get", "Delete"]
        key_permissions         = ["List", "Create"]
        certificate_permissions = ["List", "Create", "Import", "Delete"]
      }
  ]
  # Access Policy for the Client Deployment MSI.
  managed_identity_access_policy = {
        object_id          = data.azuread_client_config.current.object_id
        secret_permissions = [
          "List",
          "Set",
          "Get",
          "Delete",
          "Purge",
          "Recover"
        ]
        key_permissions     = [
          "List",
          "Create",
          "Update",
          "Import",
          "Get",
          "Encrypt",
          "Decrypt",
          "Sign",
          "Verify",
          "WrapKey",
          "UnwrapKey",
          "Delete",
          "Purge",
          "Recover"
        ]
        certificate_permissions = [
          "List",
          "Recover",
          "Delete"
        ]
  }

  data_classification = local.data_classification
  service_tier = local.service_tier
  environment  = local.environment
  portfolio    = local.portfolio
  app_code     = local.app_code
  app_name     = local.app_name
  branch       = local.branch

  tfe_instance = "nonp-qat"
}

output "keyvault_name" {
  value = module.key_vault.name
}

module "postgressql-flexible-server" {
  source = "./module"
 depends_on = [
   module.resource_group_server,
   module.key_vault
 ]
 providers = {
   azurerm.dns_zone_database  = azurerm.dns_zone_database
   azurerm                    = azurerm
   corepipeline               = corepipeline
 }
 keyvault_name            = module.key_vault.name
 keyvault_resource_group  = module.resource_group_server.resource_group_name
 leaf_resources = {
   virtual_network_name                = local.virtual_network_name
   virtual_network_resource_group_name = local.virtual_network_resource_group_name
   main_resource_group_name            = module.resource_group_server.resource_group_name
   main_resource_group_location        = local.location
   postgresql_subnet_name              = local.subnet_name
   pe_subnet_name                      = local.pe_subnet_name
 }
 zone = 1
 tier = "GeneralPurpose"
 size = "D4s_v3"
 storage_mb = 32768
 postgresql_version = 12
 backup_retention_days = 14
 geo_redundant_backup_enabled = false
 
 maintenance_window = {
   day_of_week  = 3
   start_hour   = 3
   start_minute = 0
 }

#   # These 3 need to be moved into sub-module
#  databases_names     = ["mydatabase"]
#  databases_collation = { mydatabase = "en_US.UTF8" }
#  databases_charset   = { mydatabase = "UTF8" }

 standby_zone = 2

 postgresql_log_settings = [
   {
     category          = "PostgreSQLLogs"
     enabled           = true
     retention_enabled = true
     retention_days    = 30
   },
 ]

 # Metrics settings
 postgresql_metric_settings = [
   {
     category          = "allMetrics"
     enabled           = true
     retention_enabled = true
     retention_days    = 0
   }
 ]
 service_tier = local.service_tier
 environment  = local.environment
 portfolio    = local.portfolio
 app_code     = local.app_code
 app_name     = local.app_name
 branch       = local.branch
}

module "pgfs_database" {
 source = "./module/modules/database"
 databases_names     = ["mydatabase"]
 server_id = module.postgressql-flexible-server.id
 databases_collation = { mydatabase = "en_US.UTF8" }
 databases_charset   = { mydatabase = "UTF8" }
}
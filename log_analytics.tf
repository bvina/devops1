# All the things to configure log analytics and monitoring

#########################
# resource groups
#########################
data "azurerm_resource_group" "postresql_resource_group" {
  name     = var.leaf_resources.main_resource_group_name
}
# Creates Log Anaylytics Workspace
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.postgresql_log_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.postresql_resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "pgsf" {
  name                       = join("-", [local.postgresql_server_name, "diagnostics"])
  target_resource_id         = data.azurerm_postgresql_flexible_server.pgsfdata.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-schema#service-specific-schemas for log schema options

  dynamic "log" {
    for_each = var.postgresql_log_settings

    content { 
      category = log.value.category
      enabled  = log.value.enabled
      retention_policy {
        enabled = log.value.retention_enabled
        days    = log.value.retention_days
      }
    }
  }
  dynamic "metric" {
    for_each = var.postgresql_metric_settings

    content {
      category = metric.value.category
      enabled  = metric.value.enabled
      retention_policy {
        enabled = metric.value.retention_enabled
        days    = metric.value.retention_days
      }
    }
  }
}
output "log_analytics_workspace" {
  description = "Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.name
}


variable "postgresql_server_name" {
  description = "The name of PG Server instance."
  type        = string
  default     = ""
}

variable "leaf_resources" {
  description = "LEAF resources."
  type = object({
    main_resource_group_name            = string  # The name of the Resource Group where PostgresSQL instance gets deployed to.
    virtual_network_resource_group_name = string  # The name of the virtual network, for private endpoint.
    virtual_network_name                = string  # The name of the resource group of the virtual network.
    postgresql_subnet_name              = string  # The name of the subnet which should be delegated.
  })
}

variable "tier" {
  description = "Tier for PostgreSQL Flexible server sku : https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute-storage. Possible values are: GeneralPurpose, Burstable, MemoryOptimized."
  type        = string
  default     = "GeneralPurpose"
}

variable "size" {
  description = "Size for PostgreSQL Flexible server sku : https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute-storage."
  type        = string
  default     = "D2ds_v4"
}

variable "admin" {
  description = "PostgreSQL administrator login and password."
  type = object({
    login    = string
    password = string
  })
  default     = {
    login    = ""
    password = ""
  }
  sensitive  = true
}

variable "storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  type        = number
  default     = 5120
}

variable "postgresql_version" {
  type        = string
  default     = "11"
  description = "Valid values are 9.5, 9.6, 10, 10.0, and 11"
}

variable "backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  type        = number
  default     = 10
}

variable "geo_redundant_backup_enabled" {
  description = "Turn Geo-redundant server backups on/off. Not available for the Basic tier."
  type        = bool
  default     = true
}

variable "zone" {
  description = "Specify availability-zone for PostgreSQL Flexible main Server."
  type        = number
  default     = 1
}

variable "standby_zone" {
  description = "Specify availability-zone to enable high_availability and create standby PostgreSQL Flexible Server. (Null to disable high-availability)"
  type        = number
  default     = 2
}

variable "maintenance_window" {
  description = "Map of maintenance window configuration."
  type        = map(number)
  default     = null
}

variable "databases_names" {
  description = "List of databases names to create."
  type        = list(string)
}

variable "databases_charset" {
  description = "Valid PostgreSQL charset : https://www.postgresql.org/docs/current/multibyte.html#CHARSET-TABLE"
  type        = map(string)
  default     = {}
}

variable "databases_collation" {
  description = "Valid PostgreSQL collation : http://www.postgresql.cn/docs/13/collation.html - be careful about https://docs.microsoft.com/en-us/windows/win32/intl/locale-names?redirectedfrom=MSDN"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for all resources."
  type        = map(string)
  default     = {}
}

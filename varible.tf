
variable "resource_group_name" {
  default     = "rg"
  type = string
  description = "name of the resource_group"
  }

variable "resource_group_location" {
  default     = "eastus"
  type = string
  description = "Location of the resource group."
}

variable "servicebus_namespaces_queues" {
  type = map(object({
    sku            = string
    capacity       = number
    zone_redundant = bool
    queues = map(object({
      auto_delete_on_idle                     = string
      dead_lettering_on_message_expiration    = bool
      default_message_ttl                     = string
      duplicate_detection_history_time_window = string
      enable_batched_operations               = bool
      enable_express                          = bool
      enable_partitioning                     = bool
      lock_duration                           = string
      max_delivery_count                      = number
      max_size_in_megabytes                   = string
      requires_duplicate_detection            = bool
      requires_session                        = bool
      status                                  = string
      reader                                  = bool
      sender                                  = bool
      manage                                  = bool
    }))
    topics = map(object({
      auto_delete_on_idle                     = string
      default_message_ttl                     = string
      duplicate_detection_history_time_window = string
      enable_express                          = bool
      max_delivery_count                      = number
      max_size_in_megabytes                   = string
      status                                  = string
      reader                                  = bool
      sender                                  = bool
      manage                                  = bool
    }))
  }))
  default = {
    "sb" = {
      capacity = 1
      queues = {
        "qu1" = {
          auto_delete_on_idle                     = "PT10M"
          dead_lettering_on_message_expiration    = false
          default_message_ttl                     = "PT10M"
          duplicate_detection_history_time_window = "PT10M"
          enable_batched_operations               = true
          enable_express                          = false
          enable_partitioning                     = false
          lock_duration                           = "PT1M"
          max_delivery_count                      = 10
          max_size_in_megabytes                   = "1024"
          requires_duplicate_detection            = false
          requires_session                        = false
          status                                  = "Active"
          reader                                  = false
          sender                                  = false
          manage                                  = false
        }
      }
      sku            = "Premium"
      topics         = {
        topic1 ={
          auto_delete_on_idle                     = "PT10M"
          default_message_ttl                     = "PT10M"
          duplicate_detection_history_time_window = "PT10M"
          enable_express                          = true
          max_delivery_count                      = 1
          max_size_in_megabytes                   = "1024"
          status                                  = "Active"
          reader                                  = false
          sender                                  = false
          manage                                  = false
        }
      }
      zone_redundant = false
    }
  }
}

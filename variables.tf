
variable "vcns" {
  description = "All VCNs and their subnets"
  type = map(object({
    cidr        = string
    oke_cluster = bool
    oke_cluster_details = optional(object({
      version          = string
      minimum_nodes    = number
      maximum_nodes    = number
      cpu              = number
      memory           = number
      shape            = string
      boot_volume_size = string
      public_key       = string
      tags = list(object({
        key   = string
        value = string
      }))
      labels = list(object({
        key   = string
        value = string
      }))
    }))
    subnets = map(object({
      cidr         = string
      type         = string
      display_name = optional(string)
      dns_label    = optional(string)
      security_list = object({
        ingress_security_rules = list(object({
          protocol    = string
          source      = string
          description = string
        }))
        egress_security_rules = list(object({
          protocol    = string
          destination = string
          description = string
        }))
      })
    }))
    route_tables = map(object({
      display_name = optional(string)
      routes = list(object({
        network_entity_id = string
        destination_type  = string
        destination       = string
        description       = string
      }))
    }))
  }))
}

variable "additonal_route_tables" {
  description = "The route tables for NAT gateway and Hub Transit"
  type = map(object({
    display_name = optional(string)
    routes = list(object({
      network_entity_id = string
      destination_type  = string
      destination       = string
      description       = string
    }))
  }))
}

variable "firewall_private_ip" {
  type        = string
  default     = null
  description = "The privateIp OCID of the firewall"
}

variable "tansit_route_table" {
  type        = string
  default     = null
  description = "The OCID of the transit route table"
}

variable "natgw_route_table" {
  type        = string
  default     = null
  description = "The OCID of the transit route table"
}

variable "root_compartment_id" {
  type    = string
  description = "The compartment where terraform configuration will provision resources"
}

variable "oke_addons" {
  description = "Essintial addons for OKE"
  type = map(object({
    name = string
    options = list(object({
      key   = string
      value = string
    }))
  }))
}

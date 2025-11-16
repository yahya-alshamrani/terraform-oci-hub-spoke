vcns = {
  HUB = {
    cidr        = "10.99.0.0/16"
    oke_cluster = false
    subnets = {
      HUB_PUBLIC = {
        cidr = "10.99.16.0/20"
        type = "public"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "10.0.0.0/8"
              description = "Allow all inbound traffic"
            },
            {
              protocol    = "all"
              source      = "51.36.227.77/32"
              description = "Allow all inbound traffic from PC"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      HUB_PRIVATE = {
        cidr = "10.99.0.0/20"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
    }
    route_tables = {
      PRIVATE_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Route all Oracle service traffic to Service Gateway"
          },
          {
            network_entity_id = "NATGW"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Send all external traffic to NAT Gateway"
          },
          {
            network_entity_id = "DRG"
            destination_type  = "CIDR_BLOCK"
            destination       = "10.0.0.0/8"
            description       = "Send all inter-VCN traffic through DRG"
          }
        ]
      }
      PUBLIC_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Route all Oracle service traffic to Service Gateway"
          },
          {
            network_entity_id = "IGW"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Route all Oracle service traffic to Service Gateway"
          },
          {
            network_entity_id = "FW"
            destination_type  = "CIDR_BLOCK"
            destination       = "10.0.0.0/8"
            description       = "Send inbound traffic to the firewall"
          }
        ]
      }
    }
  }
  DEVELOPMENT = {
    cidr        = "10.10.0.0/16"
    oke_cluster = true
    oke_cluster_details = {
      version          = "v1.34.1"
      minimum_nodes    = 1
      maximum_nodes    = 2
      cpu              = 2
      memory           = 8
      shape            = "VM.Standard.E5.Flex"
      boot_volume_size = "256"
      public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC994uNNVzsCyUkdnMoYdt/pQKiL/6tt3YtXa2ME0xlPkiqlVzyg/r9ImxmgxdnbvgeIUSQ2TtE/O9fV2NMJhPUpT87DM6G0W+S4+EV0zo0B0sZ9YKXM7i77Qon926VxRUMWYKuQMWQqn8+MLEq0l/5ECkpra/++d0b/ZT/hpvRgRwg3teqJByAsca3prtCK0VGl+62b0+ShJ44g/nDCLx1jJPVuukunO6wGPHAmT05sXG7eDt4O94dTt7qD6G4PhlK0ZUaoVip86Khy3UMsMwEethWlH7A7D+EKMopJPYYRA1yL/aRKH7cXkCWnyv2SvFD9U7aEXyC+XgvvQeEUZbeGEkHS9ZKeERGfMUh54wYmxcjCRql8sSJkz3nvHmqmKaY8pDWCUrzN7/7lFn9aFmELLNU6xKeUnE9oB2MJDeIMxMKxy3leW8kVsGqtdpehpPpZ2vDIISxQc2A1zCrpJSAVNUSG4/5vZ9ncBe2SMXCx5+wbQ06O5wqIrjJxWLUe+8="
      tags = [
        {
          key   = "env"
          value = "DEVELOPMENT"
        }
      ]
      labels = [
        # {
        #   key   = ""
        #  value = ""
        # } 
      ]
    }
    subnets = {
      DEVELOPMENT_GENERIC_VM = {
        cidr = "10.10.1.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      DEVELOPMENT_OKE_API = {
        cidr = "10.10.2.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      DEVELOPMENT_OKE_WN = {
        cidr = "10.10.3.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      DEVELOPMENT_OKE_LB = {
        cidr = "10.10.4.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      DEVELOPMENT_DBS = {
        cidr = "10.10.5.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
    }
    route_tables = {
      PRIVATE_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Oracle services via Service Gateway"
          },
          {
            network_entity_id = "DRG"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Inter-VCN via DRG"
          }
        ]
      }
      PUBLIC_RT = {
        routes = []
      }
    }
  }
  STAGING = {
    cidr        = "10.20.0.0/16"
    oke_cluster = false
    oke_cluster_details = {
      version          = "v1.34.1"
      minimum_nodes    = 3
      maximum_nodes    = 6
      cpu              = 12
      memory           = 64
      shape            = "VM.Standard.E5.Flex"
      boot_volume_size = "512"
      public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC994uNNVzsCyUkdnMoYdt/pQKiL/6tt3YtXa2ME0xlPkiqlVzyg/r9ImxmgxdnbvgeIUSQ2TtE/O9fV2NMJhPUpT87DM6G0W+S4+EV0zo0B0sZ9YKXM7i77Qon926VxRUMWYKuQMWQqn8+MLEq0l/5ECkpra/++d0b/ZT/hpvRgRwg3teqJByAsca3prtCK0VGl+62b0+ShJ44g/nDCLx1jJPVuukunO6wGPHAmT05sXG7eDt4O94dTt7qD6G4PhlK0ZUaoVip86Khy3UMsMwEethWlH7A7D+EKMopJPYYRA1yL/aRKH7cXkCWnyv2SvFD9U7aEXyC+XgvvQeEUZbeGEkHS9ZKeERGfMUh54wYmxcjCRql8sSJkz3nvHmqmKaY8pDWCUrzN7/7lFn9aFmELLNU6xKeUnE9oB2MJDeIMxMKxy3leW8kVsGqtdpehpPpZ2vDIISxQc2A1zCrpJSAVNUSG4/5vZ9ncBe2SMXCx5+wbQ06O5wqIrjJxWLUe+8="
      tags = [
        {
          key   = "env"
          value = "STAGING"
        }
      ]
      labels = [
        # {
        #   key   = ""
        #   value = ""
        # }
      ]
    }
    subnets = {
      STAGING_GENERIC_VM = {
        cidr = "10.20.1.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      STAGING_OKE_API = {
        cidr = "10.20.2.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      STAGING_OKE_WN = {
        cidr = "10.20.3.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      STAGING_OKE_LB = {
        cidr = "10.20.4.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      STAGING_DBS = {
        cidr = "10.20.5.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
    }
    route_tables = {
      PRIVATE_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Oracle services via Service Gateway"
          },
          {
            network_entity_id = "DRG"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Inter-VCN via DRG"
          }
        ]
      }
      PUBLIC_RT = {
        routes = []
      }
    }
  }
  PRODUCTION = {
    cidr        = "10.30.0.0/16"
    oke_cluster = false
    oke_cluster_details = {
      version          = "v1.34.1"
      minimum_nodes    = 3
      maximum_nodes    = 6
      cpu              = 12
      memory           = 64
      shape            = "VM.Standard.E5.Flex"
      boot_volume_size = "512"
      public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC994uNNVzsCyUkdnMoYdt/pQKiL/6tt3YtXa2ME0xlPkiqlVzyg/r9ImxmgxdnbvgeIUSQ2TtE/O9fV2NMJhPUpT87DM6G0W+S4+EV0zo0B0sZ9YKXM7i77Qon926VxRUMWYKuQMWQqn8+MLEq0l/5ECkpra/++d0b/ZT/hpvRgRwg3teqJByAsca3prtCK0VGl+62b0+ShJ44g/nDCLx1jJPVuukunO6wGPHAmT05sXG7eDt4O94dTt7qD6G4PhlK0ZUaoVip86Khy3UMsMwEethWlH7A7D+EKMopJPYYRA1yL/aRKH7cXkCWnyv2SvFD9U7aEXyC+XgvvQeEUZbeGEkHS9ZKeERGfMUh54wYmxcjCRql8sSJkz3nvHmqmKaY8pDWCUrzN7/7lFn9aFmELLNU6xKeUnE9oB2MJDeIMxMKxy3leW8kVsGqtdpehpPpZ2vDIISxQc2A1zCrpJSAVNUSG4/5vZ9ncBe2SMXCx5+wbQ06O5wqIrjJxWLUe+8="
      tags = [
        {
          key   = "env"
          value = "PRODUCTION"
        }
      ]
      labels = [
        # {
        #   key   = ""
        #   value = ""
        # }
      ]
    }
    subnets = {
      PRODUCTION_GENERIC_VM = {
        cidr = "10.30.1.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      PRODUCTION_OKE_API = {
        cidr = "10.30.2.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      PRODUCTION_OKE_WN = {
        cidr = "10.30.3.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      PRODUCTION_OKE_LB = {
        cidr = "10.30.4.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      PRODUCTION_DBS = {
        cidr = "10.30.5.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
    }
    route_tables = {
      PRIVATE_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Oracle services via Service Gateway"
          },
          {
            network_entity_id = "DRG"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Inter-VCN via DRG"
          }
        ]
      }
      PUBLIC_RT = {
        routes = []
      }
    }
  }
  SHARED = {
    cidr        = "10.40.0.0/16"
    oke_cluster = false
    oke_cluster_details = {
      version          = "v1.34.1"
      minimum_nodes    = 3
      maximum_nodes    = 6
      cpu              = 8
      memory           = 32
      shape            = "VM.Standard.E5.Flex"
      boot_volume_size = "512"
      public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC994uNNVzsCyUkdnMoYdt/pQKiL/6tt3YtXa2ME0xlPkiqlVzyg/r9ImxmgxdnbvgeIUSQ2TtE/O9fV2NMJhPUpT87DM6G0W+S4+EV0zo0B0sZ9YKXM7i77Qon926VxRUMWYKuQMWQqn8+MLEq0l/5ECkpra/++d0b/ZT/hpvRgRwg3teqJByAsca3prtCK0VGl+62b0+ShJ44g/nDCLx1jJPVuukunO6wGPHAmT05sXG7eDt4O94dTt7qD6G4PhlK0ZUaoVip86Khy3UMsMwEethWlH7A7D+EKMopJPYYRA1yL/aRKH7cXkCWnyv2SvFD9U7aEXyC+XgvvQeEUZbeGEkHS9ZKeERGfMUh54wYmxcjCRql8sSJkz3nvHmqmKaY8pDWCUrzN7/7lFn9aFmELLNU6xKeUnE9oB2MJDeIMxMKxy3leW8kVsGqtdpehpPpZ2vDIISxQc2A1zCrpJSAVNUSG4/5vZ9ncBe2SMXCx5+wbQ06O5wqIrjJxWLUe+8="
      tags = [
        {
          key   = "env"
          value = "SHARED"
        }
      ]
      labels = [
        # {
        #   key   = ""
        #   value = ""
        # }
      ]
    }
    subnets = {
      SHARED_GENERIC_VM = {
        cidr = "10.40.1.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      SHARED_OKE_API = {
        cidr = "10.40.2.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      SHARED_OKE_WN = {
        cidr = "10.40.3.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      SHARED_OKE_LB = {
        cidr = "10.40.4.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
      SHARED_DBS = {
        cidr = "10.40.5.0/24"
        type = "private"
        security_list = {
          ingress_security_rules = [
            {
              protocol    = "all"
              source      = "0.0.0.0/0"
              description = "Allow all inbound traffic"
            }
          ]
          egress_security_rules = [
            {
              protocol    = "all"
              destination = "0.0.0.0/0"
              description = "Allow all outbound traffic"
            }
          ]
        }
      }
    }
    route_tables = {
      PRIVATE_RT = {
        routes = [
          {
            network_entity_id = "SGW"
            destination_type  = "SERVICE_CIDR_BLOCK"
            destination       = "SGW"
            description       = "Oracle services via Service Gateway"
          },
          {
            network_entity_id = "DRG"
            destination_type  = "CIDR_BLOCK"
            destination       = "0.0.0.0/0"
            description       = "Inter-VCN via DRG"
          }
        ]
      }
      PUBLIC_RT = {
        routes = []
      }
    }
  }
}

additonal_route_tables = {
  NATGW_RT = {
    routes = [
      {
        network_entity_id = "FW"
        destination_type  = "CIDR_BLOCK"
        destination       = "10.0.0.0/8"
        description       = "Send inbound traffic to the firewall"
      }
    ]
  }
  TRANSIT_RT = {
    routes = [
      {
        network_entity_id = "FW"
        destination_type  = "CIDR_BLOCK"
        destination       = "0.0.0.0/0"
        description       = "Send inbound traffic to the firewall"
      },
      {
        network_entity_id = "FW"
        destination_type  = "CIDR_BLOCK"
        destination       = "HUB_PUBLIC_SUBNET"
        description       = "Send inbound traffic to the firewall"
      }
    ]
  }
}

oke_addons = {
  cert-management = {
    name = "CertManager"
    options = [
      {
        key   = "namespace"
        value = "certmanager-system"
      }
    ]
  }
  cluster-autoscaler = {
    name = "ClusterAutoscaler"
    options = [
      {
        key   = "authType"
        value = "workload"
      },
      {
        key   = "nodeGroupAutoDiscovery"
        value = ""
      }
    ]
  }
  istio = {
    name = "Istio"
    options = [
      {
        key   = "enableIngressGateway"
        value = "true"
      },
      {
        key   = "namespace"
        value = "istio-system"
      }
    ]
  }
  metrics-server = {
    name    = "KubernetesMetricsServer"
    options = []
  }
}

firewall_private_ip = ""

natgw_route_table = ""

tansit_route_table = ""

root_compartment_id = ""
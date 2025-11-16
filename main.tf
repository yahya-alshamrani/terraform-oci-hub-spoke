locals {
  default_defined_tags = {
    "Oracle-Tags.CreatedBy" = "Terraform"
  }
  all_subnets = merge([
    for vcn_name, vcn_data in var.vcns : {
      for subnet_name, subnet_data in vcn_data.subnets :
      "${vcn_name}.${subnet_name}" => {
        compartment_id = oci_core_vcn.vcn[vcn_name].compartment_id
        vcn_id         = oci_core_vcn.vcn[vcn_name].id
        cidr           = subnet_data.cidr
        type           = subnet_data.type
        display_name   = subnet_name
        route_table_id = subnet_data.type == "private" ? oci_core_route_table.route_table["${vcn_name}.PRIVATE_RT"].id : oci_core_route_table.route_table["${vcn_name}.PUBLIC_RT"].id
        dns_label      = substr(lower(replace(subnet_name, "_", "")), 0, 15)
        security_list = {
          ingress_security_rules = try(subnet_data.security_list.ingress_security_rules, [])
          egress_security_rules  = try(subnet_data.security_list.egress_security_rules, [])
        }
      }
    }
  ]...)
  all_routes = merge([
    for vcn_name, vcn_data in var.vcns : {
      for route_table_name, route_table_data in vcn_data.route_tables :
      "${vcn_name}.${route_table_name}" => {
        display_name   = route_table_name
        compartment_id = oci_core_vcn.vcn[vcn_name].compartment_id
        vcn_id         = oci_core_vcn.vcn[vcn_name].id
        routes = [
          for r in try(route_table_data.routes, []) : {
            network_entity_id = (
              r.network_entity_id == "SGW" ? oci_core_service_gateway.service_gateway[vcn_name].id :
              r.network_entity_id == "NATGW" ? oci_core_nat_gateway.nat_gateway.id :
              r.network_entity_id == "IGW" ? oci_core_internet_gateway.internet_gateway.id :
              r.network_entity_id == "DRG" ? oci_core_drg.drg.id :
              r.network_entity_id == "FW" ? var.firewall_private_ip :
              r.network_entity_id
            )
            destination = (
              r.destination == "SGW" ? (
                strcontains(route_table_name, "PUBLIC") ? data.oci_core_services.all.services[1].cidr_block :
                data.oci_core_services.all.services[0].cidr_block
                ) : (
                r.destination
              )
            )
            destination_type = r.destination_type
            description      = r.description
          }
          if !(r.network_entity_id == "FW" && var.firewall_private_ip == null)
        ]
      }
    }
  ]...)
  additonal_route_tables = merge({
    for rt_name, rt_data in var.additonal_route_tables : rt_name => {
      display_name   = "${rt_name}"
      vcn_id         = oci_core_vcn.vcn["HUB"].id
      compartment_id = oci_core_vcn.vcn["HUB"].compartment_id
      route_table_id = null
      routes = [
        for r in rt_data.routes : {
          network_entity_id = (r.network_entity_id == "FW" ? var.firewall_private_ip : null)
          destination_type  = r.destination_type
          destination       = (strcontains(r.destination, "PUBLIC_SUBNET") ? oci_core_subnet.subnet["HUB.HUB_PUBLIC"].cidr_block : r.destination)
          description       = r.description
        }
        if !(r.network_entity_id == "FW" && var.firewall_private_ip == null)
      ]
    }
  })
  oke_cluster = {
    for vcn_name, vcn_data in var.vcns :
    vcn_name => merge({
      cluster_name   = "${vcn_name}_CLUSTER"
      vcn_id         = oci_core_vcn.vcn[vcn_name].id
      compartment_id = oci_core_vcn.vcn[vcn_name].compartment_id
      api_subnet_id  = oci_core_subnet.subnet["${vcn_name}.${vcn_name}_OKE_API"].id
      lb_subnet_id   = oci_core_subnet.subnet["${vcn_name}.${vcn_name}_OKE_LB"].id
      wn_subnet_id   = oci_core_subnet.subnet["${vcn_name}.${vcn_name}_OKE_WN"].id
      addons = [
        for addon_key, addon_data in var.oke_addons : {
          addon_key   = addon_key
          addon_name  = addon_data.name
          addon_label = "${vcn_name}.${addon_key}"
          addon_options = [
            for addon in addon_data.options : {
              key   = addon.key
              value = addon.value
            }
          ]
        }
      ]
      },
      try(vcn_data.oke_cluster_details, {})
    )
    if vcn_data.oke_cluster == true
  }
  oke_cluster_addon = merge([
    for cluster_name, cluster_data in local.oke_cluster : {
      for addon_key, addon_data in cluster_data.addons :
      "${cluster_name}.${addon_data.addon_key}" => {
        cluster_id = oci_containerengine_cluster.cluster[cluster_name].id
        addon_name = addon_data.addon_name
        addon_options = [
          for addon in addon_data.addon_options : {
            key   = addon.key
            value = addon.key == "nodeGroupAutoDiscovery" ? "compartmentId:${cluster_data.compartment_id},nodepoolTags:${join("&", [for t in cluster_data.tags : "${t.key}=${t.value}"])},min:${cluster_data.minimum_nodes},max:${cluster_data.maximum_nodes}" : addon.value
          }
        ]
      }
    }
  ]...)
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.root_compartment_id
  name           = "terraform_lab"
  description    = "this compartment contains the HUB and SPOKE architecture"
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
  enable_delete = true
}

resource "oci_core_vcn" "vcn" {
  for_each       = var.vcns
  cidr_block     = each.value.cidr
  compartment_id = oci_identity_compartment.this.id
  display_name   = each.key
  dns_label      = substr(lower(each.key), 0, 15)
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_subnet" "subnet" {
  for_each                   = local.all_subnets
  compartment_id             = each.value.compartment_id
  vcn_id                     = each.value.vcn_id
  cidr_block                 = each.value.cidr
  prohibit_public_ip_on_vnic = each.value.type == "private"
  display_name               = each.value.display_name
  dns_label                  = each.value.dns_label
  route_table_id             = each.value.route_table_id
  security_list_ids          = [oci_core_security_list.security_list[each.key].id]
  depends_on = [
    oci_core_security_list.security_list
  ]
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_security_list" "security_list" {
  for_each       = local.all_subnets
  compartment_id = each.value.compartment_id
  vcn_id         = each.value.vcn_id
  display_name   = "${each.value.display_name}-SL"
  dynamic "ingress_security_rules" {
    for_each = each.value.security_list.ingress_security_rules
    content {
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      description = try(ingress_security_rules.value.description, null)
    }
  }
  dynamic "egress_security_rules" {
    for_each = each.value.security_list.egress_security_rules
    content {
      protocol    = egress_security_rules.value.protocol
      destination = egress_security_rules.value.destination
      description = try(egress_security_rules.value.description, null)
    }
  }
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

data "oci_core_services" "all" {}

resource "oci_core_service_gateway" "service_gateway" {
  for_each       = var.vcns
  compartment_id = oci_core_vcn.vcn[each.key].compartment_id
  vcn_id         = oci_core_vcn.vcn[each.key].id
  display_name   = "${each.key}_SWGW"
  services {
    service_id = data.oci_core_services.all.services.0.id
  }
}

resource "oci_core_drg" "drg" {
  compartment_id = oci_identity_compartment.this.id
  display_name   = "DRG"
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_drg_attachment" "drg_attachment" {
  for_each           = var.vcns
  drg_id             = oci_core_drg.drg.id
  display_name       = "${each.key}_ATTACHMENT"
  drg_route_table_id = each.key != "HUB" ? oci_core_drg_route_table.spoke_attachment_route_table.id : oci_core_drg_route_table.hub_attachment_route_table.id
  network_details {
    id             = oci_core_vcn.vcn[each.key].id
    type           = "VCN"
    route_table_id = each.key == "HUB" ? var.tansit_route_table : null
  }
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_drg_route_table" "spoke_attachment_route_table" {
  drg_id       = oci_core_drg.drg.id
  display_name = "SPOKE_ATTACHMENT_ROUTE_TABLE"
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_drg_route_table_route_rule" "vcn_attachment_route_table_static_rule" {
  drg_route_table_id         = oci_core_drg_route_table.spoke_attachment_route_table.id
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.drg_attachment["HUB"].id
}

resource "oci_core_drg_route_table" "hub_attachment_route_table" {
  drg_id                           = oci_core_drg.drg.id
  display_name                     = "HUB_ATTACHMENT_ROUTE_TABLE"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.drg_import_route_distribution.id
  defined_tags                     = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_drg_route_distribution" "drg_import_route_distribution" {
  distribution_type = "IMPORT"
  drg_id            = oci_core_drg.drg.id
  display_name      = "DRG_IMPORT_ROUTE_DISTRIBUTION"
  defined_tags      = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_drg_route_distribution_statement" "drg_import_route_distribution_statement" {
  drg_route_distribution_id = oci_core_drg_route_distribution.drg_import_route_distribution.id
  priority                  = 100
  match_criteria {
    match_type      = "DRG_ATTACHMENT_TYPE"
    attachment_type = "VCN"
  }
  action = "ACCEPT"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = oci_core_vcn.vcn["HUB"].compartment_id
  vcn_id         = oci_core_vcn.vcn["HUB"].id
  enabled        = true
  display_name   = "INTERNET_GATEWAY"
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_public_ip" "nat_public_ip" {
  compartment_id = oci_core_vcn.vcn["HUB"].compartment_id
  lifetime       = "RESERVED"
  display_name   = "NAT_PUBLIC_IP"
  lifecycle {
    #prevent_destroy = true
  }
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = oci_core_vcn.vcn["HUB"].compartment_id
  vcn_id         = oci_core_vcn.vcn["HUB"].id
  display_name   = "NAT_GATEWAY"
  public_ip_id   = oci_core_public_ip.nat_public_ip.id
  route_table_id = var.natgw_route_table
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_route_table" "route_table" {
  for_each       = local.all_routes
  compartment_id = each.value.compartment_id
  vcn_id         = each.value.vcn_id
  display_name   = each.value.display_name
  dynamic "route_rules" {
    for_each = each.value.routes
    content {
      network_entity_id = route_rules.value.network_entity_id
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      description       = route_rules.value.description
    }
  }
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_core_route_table" "addional_route_table" {
  for_each       = local.additonal_route_tables
  compartment_id = each.value.compartment_id
  vcn_id         = each.value.vcn_id
  display_name   = each.value.display_name
  dynamic "route_rules" {
    for_each = each.value.routes
    content {
      network_entity_id = route_rules.value.network_entity_id
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      description       = route_rules.value.description
    }
  }
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

data "oci_objectstorage_namespace" "tenancy_bucket_namespace" {}

resource "oci_objectstorage_bucket" "images_bucket" {
  compartment_id = oci_identity_compartment.this.id
  name           = "Images"
  namespace      = data.oci_objectstorage_namespace.tenancy_bucket_namespace.namespace
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_objectstorage_object" "download_pfSense_image" {
  bucket    = oci_objectstorage_bucket.images_bucket.name
  namespace = data.oci_objectstorage_namespace.tenancy_bucket_namespace.namespace
  object    = "pfSense CE 2.8.1 uefi vmdk"
  source    = "${path.root}/images/pfSense-v2.8.1-uefi.vmdk"
  timeouts {}
}

resource "oci_core_image" "pfSense_image" {
  compartment_id = oci_identity_compartment.this.id
  display_name   = oci_objectstorage_object.download_pfSense_image.object
  launch_mode    = "PARAVIRTUALIZED"
  image_source_details {
    source_type              = "objectStorageTuple"
    bucket_name              = oci_objectstorage_bucket.images_bucket.name
    namespace_name           = data.oci_objectstorage_namespace.tenancy_bucket_namespace.namespace
    object_name              = oci_objectstorage_object.download_pfSense_image.object
    operating_system         = "pfSense CE"
    operating_system_version = "2.8.1"
    source_image_type        = "VMDK"
  }
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = oci_identity_compartment.this.id
}

resource "oci_core_instance" "firewall_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.this.id
  shape               = "VM.Standard.E5.Flex"
  agent_config {
    are_all_plugins_disabled = false
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  create_vnic_details {
    private_ip             = "10.99.10.1"
    assign_public_ip       = false
    skip_source_dest_check = true
    subnet_id              = oci_core_subnet.subnet["HUB.HUB_PRIVATE"].id
  }
  display_name = "FIREWALL-01"

  shape_config {
    memory_in_gbs = 8
    ocpus         = 2
  }
  source_details {
    source_id               = oci_core_image.pfSense_image.id
    source_type             = "image"
    boot_volume_size_in_gbs = 100
  }
  preserve_boot_volume = false
  defined_tags         = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

data "oci_core_vnic_attachments" "fw_vnic_attach" {
  compartment_id = oci_identity_compartment.this.id
  instance_id    = oci_core_instance.firewall_instance.id
}

data "oci_core_vnic" "fw_vnic" {
  vnic_id = data.oci_core_vnic_attachments.fw_vnic_attach.vnic_attachments[0].vnic_id
}

data "oci_core_private_ips" "firewall_private_ip" {
  vnic_id = data.oci_core_vnic.fw_vnic.id
}

output "firewall_private_ip_ocid" {
  value = data.oci_core_private_ips.firewall_private_ip.private_ips[0].id
}

output "tansit_route_table_ocid" {
  value = oci_core_route_table.addional_route_table["TRANSIT_RT"].id
}

output "natgw_route_table_ocid" {
  value = oci_core_route_table.addional_route_table["NATGW_RT"].id
}

resource "oci_containerengine_cluster" "cluster" {
  for_each           = local.oke_cluster
  compartment_id     = each.value.compartment_id
  kubernetes_version = each.value.version
  name               = each.value.cluster_name
  vcn_id             = each.value.vcn_id
  endpoint_config {
    subnet_id = each.value.api_subnet_id
  }
  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
  options {
    ip_families           = ["IPv4"]
    service_lb_subnet_ids = [each.value.lb_subnet_id]
  }
  type         = "ENHANCED_CLUSTER"
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

resource "oci_containerengine_addon" "cluster_addon" {
  for_each                         = local.oke_cluster_addon
  addon_name                       = each.value.addon_name
  cluster_id                       = each.value.cluster_id
  remove_addon_resources_on_delete = true
  dynamic "configurations" {
    for_each = each.value.addon_options
    content {
      key   = configurations.value.key
      value = configurations.value.value
    }
  }
  override_existing = true
}

resource "oci_containerengine_node_pool" "node_pool" {
  for_each       = local.oke_cluster
  cluster_id     = oci_containerengine_cluster.cluster[each.key].id
  compartment_id = oci_core_vcn.vcn[each.key].compartment_id
  name           = "${each.key}_OKE_VN_POOL_1"
  node_shape     = each.value.shape
  freeform_tags = {
    for tag in each.value.tags : tag.key => tag.value
  }
  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.value.key
      value = initial_node_labels.value.value
    }
  }
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = each.value.wn_subnet_id
    }
    size = each.value.minimum_nodes
  }
  # node_eviction_node_pool_settings {
  #   eviction_grace_duration = "PT0M"
  #   is_force_action_after_grace_duration = true
  #   is_force_delete_after_grace_duration = true
  # }
  # node_pool_cycling_details {
  #   cycle_modes             = ["INSTANCE_REPLACE"]
  #   is_node_cycling_enabled = true
  #   maximum_surge           = 1
  #   maximum_unavailable     = 1
  # }
  node_shape_config {
    memory_in_gbs = each.value.memory
    ocpus         = each.value.cpu
  }
  node_source_details {
    source_type = "IMAGE"
    image_id = [
      for img in data.oci_containerengine_node_pool_option.oke.sources :
      img.image_id
      if !(
        strcontains(img.source_name, "aarch") ||
        strcontains(img.source_name, "GPU")
      )
    ][0]
    boot_volume_size_in_gbs = each.value.boot_volume_size
  }
  node_metadata = {
    user_data = base64encode(file("${path.module}/scripts/oke-cloud-init.sh"))
  }
  ssh_public_key = each.value.public_key
  defined_tags   = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}

data "oci_containerengine_node_pool_option" "oke" {
  compartment_id      = oci_identity_compartment.this.id
  node_pool_option_id = "all"
}

data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
  cluster_id = oci_containerengine_cluster.cluster["DEVELOPMENT"].id
}

output "cluster_kube_config" {
  value = data.oci_containerengine_cluster_kube_config.cluster_kube_config
}

resource "oci_identity_policy" "clusterautoscaler_policy" {
  for_each       = local.oke_cluster
  compartment_id = each.value.compartment_id
  description    = "Allow clusterAutoscaler to be able to manage the nood pool"
  name           = "clusterautoscaler_manage_nood_pool_policy"
  statements = [
    "Allow any-user to manage cluster-node-pools in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}",
    "Allow any-user to manage instance-family in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}",
    "Allow any-user to use subnets in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}",
    "Allow any-user to read virtual-network-family in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}",
    "Allow any-user to use vnics in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}",
    "Allow any-user to inspect compartments in compartment id ${each.value.compartment_id} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster[each.key].id}'}"
  ]
  defined_tags = local.default_defined_tags
  lifecycle {
    ignore_changes = [
      defined_tags["Oracle-Tags.CreatedOn"]
    ]
  }
}
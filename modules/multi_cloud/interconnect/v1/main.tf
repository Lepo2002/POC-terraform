resource "google_compute_interconnect_attachment" "gcp_interconnect" {
  name                     = "${var.environment}-${var.interconnect_name}"
  project                  = var.gcp_project_id
  region                   = var.gcp_region
  type                     = "PARTNER"
  router                   = var.gcp_router_id
  encryption               = var.enable_encryption ? "IPSEC" : "NONE"
  admin_enabled            = true
  
  edge_availability_domain = var.edge_availability_domain
  
  dynamic "ipsec_internal_addresses" {
    for_each = var.ipsec_internal_addresses
    content {
      name              = ipsec_internal_addresses.key
      address           = ipsec_internal_addresses.value.address
      address_type      = ipsec_internal_addresses.value.address_type
      subnetwork        = ipsec_internal_addresses.value.subnetwork
    }
  }
}

resource "azurerm_express_route_circuit" "azure_express_route" {
  count = var.create_azure_express_route ? 1 : 0
  
  name                  = "${var.environment}-${var.express_route_name}"
  resource_group_name   = var.azure_resource_group_name
  location              = var.azure_location
  service_provider_name = "Google Cloud Platform"
  peering_location      = var.azure_peering_location
  bandwidth_in_mbps     = var.azure_bandwidth_mbps
  
  sku {
    tier   = var.azure_express_route_tier
    family = "MeteredData"
  }
  
  tags = {
    environment = var.environment
  }
}

resource "azurerm_express_route_circuit_authorization" "azure_auth" {
  count = var.create_azure_express_route ? 1 : 0
  
  name                       = "${var.environment}-auth"
  express_route_circuit_name = azurerm_express_route_circuit.azure_express_route[0].name
  resource_group_name        = var.azure_resource_group_name
}

resource "azurerm_virtual_network_gateway" "azure_vpn_gateway" {
  count = var.create_azure_vpn_backup ? 1 : 0
  
  name                = "${var.environment}-vpn-gateway"
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  
  type     = "Vpn"
  vpn_type = "RouteBased"
  
  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2"
  
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = var.azure_vpn_public_ip_id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.azure_gateway_subnet_id
  }
  
  vpn_client_configuration {
    address_space = ["172.16.201.0/24"]
    
    root_certificate {
      name = "VPN-Root-Certificate"
      
      public_cert_data = var.azure_vpn_root_cert
    }
  }
}

resource "google_compute_ha_vpn_gateway" "gcp_vpn_gateway" {
  count = var.create_gcp_vpn_backup ? 1 : 0
  
  name    = "${var.environment}-vpn-gateway"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = var.gcp_network_id
}

resource "google_compute_external_vpn_gateway" "azure_gateway" {
  count = var.create_gcp_vpn_backup ? 1 : 0
  
  name            = "${var.environment}-azure-gateway"
  project         = var.gcp_project_id
  redundancy_type = "TWO_IPS_REDUNDANCY"
  
  interface {
    id         = 0
    ip_address = var.azure_vpn_ip_1
  }
  
  interface {
    id         = 1
    ip_address = var.azure_vpn_ip_2
  }
}

resource "google_compute_vpn_tunnel" "gcp_vpn_tunnel_1" {
  count = var.create_gcp_vpn_backup ? 1 : 0
  
  name                   = "${var.environment}-tunnel-1"
  project                = var.gcp_project_id
  region                 = var.gcp_region
  vpn_gateway            = google_compute_ha_vpn_gateway.gcp_vpn_gateway[0].id
  peer_external_gateway  = google_compute_external_vpn_gateway.azure_gateway[0].id
  shared_secret          = var.vpn_shared_secret
  router                 = var.gcp_router_id
  peer_external_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "gcp_vpn_tunnel_2" {
  count = var.create_gcp_vpn_backup ? 1 : 0
  
  name                   = "${var.environment}-tunnel-2"
  project                = var.gcp_project_id
  region                 = var.gcp_region
  vpn_gateway            = google_compute_ha_vpn_gateway.gcp_vpn_gateway[0].id
  peer_external_gateway  = google_compute_external_vpn_gateway.azure_gateway[0].id
  shared_secret          = var.vpn_shared_secret
  router                 = var.gcp_router_id
  peer_external_gateway_interface = 1
}
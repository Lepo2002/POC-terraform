
module "gke" {
  source = "../../modules/gcp_kubernates/v1"

  project_id = var.project_id
  cluster_name = "prod-cluster"
  region = var.region
  zone = var.zone
  regional = true

  network = module.vpc.network_name
  subnetwork = module.vpc.subnet_names[0]

  cluster_secondary_range_name = "pod-range"
  services_secondary_range_name = "svc-range"

  enable_private_nodes = true
  master_ipv4_cidr_block = "172.16.0.0/28"

  initial_node_count = 3
  min_node_count = 3
  max_node_count = 10
  machine_type = "e2-standard-2"

  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "VPC"
    }
  ]

  node_labels = {
    environment = "production"
  }

  node_tags = ["gke-node", "production"]
}


locals {
  cluster_type = "regional"
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)

  ignore_annotations = [
    "^iam.gke.io\\/.*"
  ]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 36.0"

  project_id               = var.project_id
  name                     = "${local.cluster_type}-cluster${var.cluster_name_suffix}"
  region                   = var.region
  network                  = var.network
  subnetwork               = var.subnetwork
  ip_range_pods            = var.ip_range_pods
  ip_range_services        = var.ip_range_services
  remove_default_node_pool = true
  service_account          = "create"
  node_metadata            = "GKE_METADATA"
  deletion_protection      = false
  node_pools = [
    {
      name         = "wi-pool"
      min_count    = 1
      max_count    = 3
      auto_upgrade = true
    }
  ]
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "qr-back"
    namespace = "default"
    labels = {
      app = "qr-back"
    }
  }
  spec {
    selector = {
      app = "qr-back"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name = "qr-back"
    namespace = "default"
    labels = {
      app = "qr-back"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "qr-back"
      }
    }
    template {
      metadata {
        labels = {
          app = "qr-back"
        }
      }
      spec {
        service_account_name = module.workload_identity.k8s_service_account_name
        container {
          name  = "qr-back"
          image = "ajohn1/qr-back:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "qr-front"
    namespace = "default"
    labels = {
      app = "qr-front"
    }
  }
  spec {
    selector = {
      app = "qr-front"
    }
    port {
      port        = 3000
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "qr-front"
    namespace = "default"
    labels = {
      app = "qr-front"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "qr-front"
      }
    }
    template {
      metadata {
        labels = {
          app = "qr-front"
        }
      }
      spec {
        container {
          name  = "qr-front"
          image = "ajohn1/qr-front:latest"
          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

# example without existing KSA
module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "~> 36.0"

  project_id          = var.project_id
  name                = "iden-${module.gke.name}"
  namespace           = "default"
  use_existing_k8s_sa = false
}

# Grant SA access to bucket
resource "google_storage_bucket_iam_member" "backend_bucket_access" {
  bucket = "qr-bucket-1"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
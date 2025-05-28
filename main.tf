provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_storage_bucket" "civil_ai_bucket" {
  name     = "${var.project_id}-storage"
  location = var.region
}

resource "google_compute_instance" "gpu_instance" {
  name         = "civil-ai-gpu"
  machine_type = "a2-highgpu-1g"
  zone         = var.zone

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  boot_disk {
    initialize_params {
      image = "projects/deeplearning-platform-release/global/images/family/tf-latest-gpu"
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  guest_accelerator {
    type  = "nvidia-tesla-a100"
    count = 1
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_sql_database_instance" "civil_ai_db" {
  name             = "civil-ai-sql"
  region           = var.region
  database_version = "MYSQL_8_0"

  settings {
    tier = "db-f1-micro"
    disk_size = 10
  }
}

resource "google_compute_instance" "vector_db" {
  name         = "civil-ai-vector-db"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      sudo apt update
      sudo apt install -y docker.io
      sudo docker run -d -p 19530:19530 milvusdb/milvus:v2.2.11
    EOT
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_cloud_run_service" "civil_ai_app" {
  name     = "civil-ai-app"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffics {
    percent         = 100
    latest_revision = true
  }
}

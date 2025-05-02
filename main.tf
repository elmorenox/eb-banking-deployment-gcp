provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create a VPC
resource "google_compute_network" "jenkins_vpc" {
  name                    = "jenkins-vpc"
  auto_create_subnetworks = false

  # Apply tags
  description = "VPC for Jenkins deployment"
}

# Create a subnet
resource "google_compute_subnetwork" "jenkins_subnet" {
  name          = "jenkins-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.jenkins_vpc.id

  # Enable private Google access
  private_ip_google_access = true
}

# Create a firewall rule for Jenkins
resource "google_compute_firewall" "jenkins_firewall" {
  name    = var.firewall_name
  network = google_compute_network.jenkins_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }

  # Allow traffic from anywhere to Jenkins and SSH ports
  source_ranges = ["0.0.0.0/0"]
  
  target_tags = ["jenkins"]
}

# Create a VM instance for Jenkins
resource "google_compute_instance" "jenkins_server" {
  name         = "jenkins-server"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["jenkins"]

  boot_disk {
    initialize_params {
      image = var.compute_image
      size  = 50  # 50 GB disk
    }
  }

  network_interface {
    network    = google_compute_network.jenkins_vpc.name
    subnetwork = google_compute_subnetwork.jenkins_subnet.name
    
    # Assign a public IP
    access_config {
      // Ephemeral public IP
    }
  }

  # Add metadata for SSH keys if needed
  # metadata = {
  #   ssh-keys = "USERNAME:${file("~/.ssh/id_rsa.pub")}"
  # }

  metadata_startup_script = templatefile("jenkins_userdata.sh", {
    github_repo_url    = var.github_repo_url,
    app_engine_service = var.app_engine_service,
    service_account_email = var.service_account_email
  })

  # Using service account email that you've set up manually
  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

# Reserve a static external IP address (optional)
resource "google_compute_address" "jenkins_ip" {
  name   = "jenkins-static-ip"
  region = var.region
}

# Output the public IP of the Jenkins server
output "jenkins_ip" {
  value = google_compute_instance.jenkins_server.network_interface[0].access_config[0].nat_ip
}
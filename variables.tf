variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "compute_image" {
  description = "Image for compute instances"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
}

variable "firewall_name" {
  description = "Name of the Jenkins firewall rule"
  type        = string
  default     = "jenkins-firewall"
}

variable "resource_tags" {
  description = "Tags to apply to resources (used as labels in GCP)"
  type        = map(string)
  default = {
    project     = "jenkins-app-engine-deployment"
    environment = "dev"
  }
}

variable "github_repo_url" {
  description = "URL of the GitHub repository to connect to Jenkins"
  type        = string
}

variable "app_engine_service" {
  description = "Name of the App Engine service"
  type        = string
  default     = "banking-app"
}

variable "service_account_email" {
  description = "Email of the service account for Jenkins"
  type        = string
}
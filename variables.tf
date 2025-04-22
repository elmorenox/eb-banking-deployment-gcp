variable "eb_environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
  default     = "eb-banking-env"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "jenkins_sg_name" {
  description = "Name of the Jenkins security group"
  type        = string
  default     = "jenkins-sg"
}

variable "jenkins_role_name" {
  description = "Name of the IAM role for Jenkins"
  type        = string
  default     = "jenkins-role"
}

variable "jenkins_profile_name" {
  description = "Name of the IAM instance profile for Jenkins"
  type        = string
  default     = "jenkins-profile"
}

variable "resource_tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "jenkins-eb-deployment"
    Environment = "dev"
  }
}

variable "github_repo_url" {
  description = "URL of the GitHub repository to connect to Jenkins"
  type        = string
  default     = "https://github.com/elmorenox/eb-banking-deployment.git"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}
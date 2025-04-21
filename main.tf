provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.resource_tags, {
    Name = "jenkins-vpc"
  })
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.resource_tags, {
    Name = "jenkins-public-subnet"
  })
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = merge(var.resource_tags, {
    Name = "jenkins-igw"
  })
}

# Create a route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.resource_tags, {
    Name = "jenkins-public-rt"
  })
}

# Associate the route table with the subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a security group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = var.jenkins_sg_name
  description = "Security group for Jenkins server"
  vpc_id      = aws_vpc.jenkins_vpc.id

  # Jenkins web interface
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.resource_tags, {
    Name = var.jenkins_sg_name
  })
}

# Create an IAM role for Jenkins EC2 instance
resource "aws_iam_role" "jenkins_role" {
  name = var.jenkins_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.resource_tags
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "eb_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk"
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# Attach additional policies that might be needed
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudformation_access" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

# Create an IAM instance profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = var.jenkins_profile_name
  role = aws_iam_role.jenkins_role.name
}

# Create an EC2 instance for Jenkins
resource "aws_instance" "jenkins_server" {
  ami                    = var.ec2_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  user_data = templatefile("jenkins_userdata.sh", {
    github_repo_url    = var.github_repo_url,
    eb_environment_name = var.eb_environment_name,
    aws_access_key     = var.aws_access_key,
    aws_secret_key     = var.aws_secret_key
  })

  tags = merge(var.resource_tags, {
    Name = "jenkins-server"
  })
}

# Output the public IP of the Jenkins server
output "jenkins_ip" {
  value = aws_instance.jenkins_server.public_ip
}
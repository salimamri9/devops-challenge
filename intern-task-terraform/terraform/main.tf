terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.10"
}

provider "aws" {
  region = var.region

  // lets plan run against fake credentials without ever calling AWS (see README)
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
}

locals {
  app_dir    = "${path.module}/../../intern-task-app"
  dockerfile = file("${local.app_dir}/Dockerfile")

  // the port is extracted from the dockerfile
  app_port = tonumber(regex("(?m)^EXPOSE\\s+(\\d+)", local.dockerfile)[0])
}

// ec2 instance
resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    admin_user     = var.admin_user
    ssh_public_key = var.ssh_public_key
    ssh_cidr       = var.ssh_cidr
    app_port       = local.app_port
    dockerfile_b64 = base64encode(local.dockerfile)
    app_py_b64     = filebase64("${local.app_dir}/app/app.py")
  })

  // cloud-init only runs on first boot, so a changed user_data can never be
  // applied to a running instance. ignore it instead of replacing the box.
  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "intern-task-app"
  }
}

// vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "intern-task-vpc"
  }
}

// subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "intern-task-public-subnet"
  }
}

// igw
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "intern-task-igw"
  }
}

// route_table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "intern-task-public-rt"
  }
}

// associate route table to subnet(virtual vpc router)
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

// security group
resource "aws_security_group" "app" {
  name        = "intern-task-app"
  description = "SSH from one CIDR, app port from anywhere"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = var.ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = local.app_port
  to_port           = local.app_port
}

// instance needs outbound to install docker and pull the base image
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

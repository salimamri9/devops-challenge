variable "region" {
  description = "the region where the resources will be deployed, closest to tunisia"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "type of the instance"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "ubuntu 24.04 amd64 ami (default is the eu-west-3 one)"
  type        = string
  default     = "ami-098a3694db632e4e5"
}

variable "admin_user" {
  description = "non-root user created on the instance, with passwordless sudo"
  type        = string
  default     = "deploy"
}

variable "ssh_public_key" {
  description = "public key allowed to ssh in as admin_user"
  type        = string
}

variable "ssh_cidr" {
  description = "the only cidr allowed to ssh in, e.g. your ip as x.x.x.x/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0)) && var.ssh_cidr != "0.0.0.0/0"
    error_message = "ssh_cidr must be a valid cidr and not 0.0.0.0/0."
  }
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "public subnet cidr block"
  type        = string
  default     = "10.0.1.0/24"
}

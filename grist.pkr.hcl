# Building an Ubuntu image with Grist for both AWS and DigitalOcean

packer {
  required_plugins {
    digitalocean = {
      version = ">= 1"
      source  = "github.com/digitalocean/digitalocean"
    }
    amazon = {
      version = ">= 1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_access_key" {
  type    = string
}

variable "aws_secret_key" {
  type    = string
}

variable "do_token" {
  type    = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "do_image" {
  type    = string
  default = "ubuntu-24-04-x64"
}

variable "aws_image_filter" {
  type    = string
  default = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

source "amazon-ebs" "ubuntu_aws" {
  ami_name      = "grist-ubuntu-{{timestamp}}"
  instance_type = var.aws_instance_type
  region        = var.region
  source_ami_filter {
    filters = {
      name                = var.aws_image_filter
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical's official Ubuntu AMIs
  }
  ssh_username  = "ubuntu"
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
}

source "digitalocean" "ubuntu_do" {
  image    = var.do_image
  region   = "nyc3"
  size     = "s-1vcpu-1gb"
  ssh_username = "root"
  api_token = var.do_token
}

build {
  sources = [
    "source.amazon-ebs.ubuntu_aws",
    "source.digitalocean.ubuntu_do"
  ]
  
  provisioner "file" {
    source = "docker-compose.yaml"
    destination = "/tmp/docker-compose.yaml"
  }

  provisioner "shell" {
    # Wait for startup to finish so we don't race with apt-get
    inline = ["sleep 10"]
  }

  provisioner "shell" {
    execute_command = "sudo bash -xc '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "installDocker"
    ]
  }
 
  # Need to figure out the story for making it easy to mount volumes for AWS
  # and DO. They each handle it differently.

  post-processor "manifest" {
    output = "manifest.json"
  }
}

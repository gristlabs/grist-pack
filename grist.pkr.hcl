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
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

variable "do_token" {
  type    = string
  default = ""
}

variable "azure_tenant_id" {
  type    = string
  default = ""
}

variable "azure_subscription_id" {
  type    = string
  default = ""
}

variable "azure_client_id" {
  type    = string
  default = ""
}

variable "azure_client_secret" {
  type    = string
  default = ""
}

variable "azure_resource_group" {
  type    = string
  default = "Grist"
}

variable "do_image" {
  type    = string
  default = "ubuntu-24-04-x64"
}

variable "aws_image_filter" {
  type    = string
  default = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

locals {
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  enabled_sources = flatten([
    var.aws_access_key != "" && var.aws_secret_key != "" ? ["source.amazon-ebs.ubuntu"] : [],
    var.do_token != "" ? ["source.digitalocean.ubuntu"] : [],
    var.azure_tenant_id != ""
    && var.azure_subscription_id != ""
    && var.azure_client_id != ""
    && var.azure_client_secret != "" ? ["source.azure-arm.ubuntu"] : []
  ])
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "grist-marketplace-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = var.aws_image_filter
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical's official Ubuntu AMIs
  }
  ssh_username              = "ubuntu"
  access_key                = var.aws_access_key
  secret_key                = var.aws_secret_key
  user_data_file            = ""
  ssh_clear_authorized_keys = true
}

source "digitalocean" "ubuntu" {
  image                     = var.do_image
  region                    = "nyc3"
  size                      = "s-1vcpu-1gb"
  api_token                 = var.do_token
  ssh_username              = "root"
  snapshot_name             = "grist-marketplace-${local.timestamp}"
  ssh_clear_authorized_keys = true
}

source "azure-arm" "ubuntu" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id

  location = "Central US"

  vm_size         = "Standard_B2s"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"

  managed_image_resource_group_name = var.azure_resource_group
  managed_image_name                = "grist-marketplace-${local.timestamp}"

  os_type      = "Linux"
  communicator = "ssh"
  ssh_username = "packer"
}

build {
  sources = local.enabled_sources

  # Pack up and send the dist
  provisioner "shell-local" {
    inline = [
      "tar --transform 's/^dist/grist-dist/' --exclude dist/persist -czvf grist-dist.tar.gz dist/"
    ]
  }
  provisioner "file" {
    source      = "grist-dist.tar.gz"
    destination = "/tmp/"
    generated   = true
  }
  provisioner "shell" {
    inline = [
      "cd /tmp/",
      "tar xvf grist-dist.tar.gz",
      "rm grist-dist.tar.gz"
    ]
  }

  provisioner "shell" {
    # Wait for startup to finish (ignore error code)
    inline = ["cloud-init status --wait || true"]
  }

  provisioner "shell" {
    # Because the default AWS image doesn't run as root but DO does,
    # easier to just sudo in both. So change the default
    # execute_command
    execute_command = "sudo bash -xc '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "scripts/install-docker",
      "scripts/setup-grist-dist",
      "scripts/setup-ufw",
      "scripts/setup-systemd",
      "scripts/setup-login-user",
      "scripts/cleanup",
    ]
  }

  provisioner "shell" {
    script = "scripts/digitalocean-img-check"
    only   = ["digitalocean.ubuntu_do"]
  }

  # Need to figure out the story for making it easy to mount volumes for AWS
  # and DO. They each handle it differently.

  # We can use this to keep track of what images have been built,
  # helps to keep track in case we want to clean them up.
  post-processor "manifest" {
    output = "manifest.json"
  }
}

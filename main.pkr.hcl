packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "ubuntu-nginx-ami"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu-jammy" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
}

build {
  name = "ubuntu-nginx-ami"
  sources = [
    "source.amazon-ebs.ubuntu-jammy",
  ]

  # provisioners are executed on the EC2 instance before the image is created
  provisioner "shell" {
    inline = [
      "echo Installing NGINX",
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo This provisioner runs last"
    ]
  }

  # post-processors are executed on the local machine after the image is created
  # will produce packer-manifest.json file
  post-processor "manifest" {}
}

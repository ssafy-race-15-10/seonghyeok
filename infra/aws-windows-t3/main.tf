terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

data "aws_vpc" "default" {
  default = true
}

data "http" "operator_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  operator_cidr = coalesce(var.operator_cidr, "${chomp(data.http.operator_ip.response_body)}/32")
}

resource "aws_key_pair" "windows" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "windows" {
  name        = "${var.name}-sg"
  description = "RDP and AirSim RPC access for SSAFY Race Windows test host"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "RDP from operator IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [local.operator_cidr]
  }

  ingress {
    description = "AirSim RPC from operator IP"
    from_port   = 41451
    to_port     = 41451
    protocol    = "tcp"
    cidr_blocks = [local.operator_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_instance" "windows" {
  ami                         = data.aws_ssm_parameter.windows_ami.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.windows.key_name
  vpc_security_group_ids      = [aws_security_group.windows.id]
  associate_public_ip_address = true
  get_password_data           = true

  user_data = <<-POWERSHELL
    <powershell>
    New-NetFirewallRule -DisplayName "AirSim RPC 41451" -Direction Inbound -Protocol TCP -LocalPort 41451 -Action Allow
    </powershell>
  POWERSHELL

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  tags = {
    Name = var.name
  }
}

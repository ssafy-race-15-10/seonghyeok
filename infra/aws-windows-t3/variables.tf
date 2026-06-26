variable "aws_region" {
  description = "AWS region for the Windows EC2 instance."
  type        = string
  default     = "ap-northeast-2"
}

variable "name" {
  description = "Name prefix for created AWS resources."
  type        = string
  default     = "ssafy-race-windows-t3"
}

variable "instance_type" {
  description = "Windows test instance type. t3.large is a low-cost experiment and may not run the simulator."
  type        = string
  default     = "t3.large"
}

variable "operator_cidr" {
  description = "Optional public IP CIDR allowed to access RDP and AirSim RPC. If null, Terraform detects the current public IP."
  type        = string
  default     = null
}

variable "key_name" {
  description = "EC2 key pair name to create."
  type        = string
  default     = "ssafy-race-windows-key"
}

variable "public_key_path" {
  description = "Path to the RSA public key used for Windows administrator password decryption."
  type        = string
  default     = "~/.ssh/aws-windows.pub"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 100
}

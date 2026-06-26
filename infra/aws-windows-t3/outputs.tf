output "public_ip" {
  description = "Public IPv4 address for RDP and AirSim RPC checks."
  value       = aws_instance.windows.public_ip
}

output "rdp_target" {
  description = "RDP connection target."
  value       = "${aws_instance.windows.public_ip}:3389"
}

output "ssh_target" {
  description = "SSH target for code deployment."
  value       = "Administrator@${aws_instance.windows.public_ip}"
}

output "security_group_id" {
  description = "Security group ID for temporary CI ingress rules."
  value       = aws_security_group.windows.id
}

output "airsim_rpc_target" {
  description = "AirSim RPC target for tools/airsim_rpc_probe.py."
  value       = "${aws_instance.windows.public_ip}:41451"
}

output "allowed_operator_cidr" {
  description = "CIDR allowed through the security group for RDP and AirSim RPC."
  value       = local.operator_cidr
}

output "administrator_password_encrypted" {
  description = "Encrypted Windows Administrator password data. Decrypt with the matching RSA private key."
  value       = aws_instance.windows.password_data
  sensitive   = true
}

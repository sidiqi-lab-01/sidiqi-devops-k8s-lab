
output "terraform_ec2_instance_id" {
  description = "Terraform-managed EC2 instance ID"
  value       = aws_instance.lab.id
}

output "terraform_ec2_private_ip" {
  description = "Terraform-managed EC2 private IP"
  value       = aws_instance.lab.private_ip
}

output "terraform_ec2_public_ip" {
  description = "Terraform-managed EC2 public IP"
  value       = aws_instance.lab.public_ip
}

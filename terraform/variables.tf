variable "aws_region" {
  description = "AWS region for the DevOps lab"
  type        = string
  default     = "us-east-1"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the DevOps lab"
  type        = string
  default     = "t3.micro"
}

variable "ec2_name" {
  description = "Name tag for the Terraform-managed EC2 instance"
  type        = string
  default     = "sidiqi-devops-lab-terraform-ec2"
}

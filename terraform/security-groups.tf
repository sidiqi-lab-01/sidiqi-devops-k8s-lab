resource "aws_security_group" "admin" {
  name        = "sidiqi-devops-admin-sg"
  description = "Security group for DevOps administration host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sidiqi-devops-admin-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "sidiqi-devops-terraform"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.admin.id]

  associate_public_ip_address = true

  tags = {
    Name = "sidiqi-devops-lab-terraform-ec2"
  }
}

# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "app_ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10**"]
  }
}

# Create an AWS Key Pair (Assuming the key pair already exists)
resource "aws_key_pair" "mykey" {
  key_name   = "myfusionkey"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub") # Ensure this path is correct

  # Prevent Terraform from attempting to recreate the key pair if it exists
  lifecycle {
    ignore_changes = [key_name]
  }
}

# Launch an EC2 Instance
resource "aws_instance" "instance-1" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mykey.key_name

  # Security Group for SSH access
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  # Remote Exec Provisioner
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl start nginx"
    ]
  }

  # Connection Configuration
  connection {
    type        = "ssh"
    user        = "ec2-user" # Ensure this matches your instance type
    private_key = file("/var/lib/jenkins/.ssh/id_rsa") # Ensure this file exists and is correct
    host        = self.public_ip
  }

  # Save Private IP Locally on Creation
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }

  # Clear Private IPs File on Destroy
  provisioner "local-exec" {
    when    = destroy
    command = "cat /dev/null > private_ips.txt"
  }
}

# Security Group to Allow SSH Access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH access from Jenkins server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["52.13.125.87/32"] # Replace with Jenkins server's public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output Public IP of the Instance
output "mypublicIP" {
  value = aws_instance.instance-1.public_ip
}

# AWS Provider Configuration
provider "aws" {
  region  = "us-west-2" # Replace with your desired region
  profile = "default"   # Optional, replace with your AWS CLI profile
}

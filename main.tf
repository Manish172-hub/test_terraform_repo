# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "app_ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10**"]
  }
}

# Import the existing Key Pair if it exists in your AWS account
# You should manually run `terraform import aws_key_pair.mykey myfusionkey` if the key pair exists

resource "aws_key_pair" "id_ed25519" {
  key_name   = "id_ed25519.pub"
  public_key =  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICis5L8i8qVZswfRtpaYQlsP0x5PndxDT/ZkNL3he1dp User@LAPTOP-G492FC2B"   # Ensure this path is correct

  # Prevent Terraform from attempting to recreate the key pair if it exists
  lifecycle {
    create_before_destroy = true
    ignore_changes = [key_name] # Ignore changes to key_name
  }
}

# Launch an EC2 Instance
resource "aws_instance" "instance-1" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.id_ed25519.key_name

  # Security Group for SSH access
  vpc_security_group_ids = [aws_security_group.ssh_access_2.id]

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

# Import the existing Security Group if it exists in your AWS account
# You should manually run `terraform import aws_security_group.ssh_access sg-xxxxxxxxx` if the security group exists

resource "aws_security_group" "ssh_access_2" {
  name        = "allow_ssh"
  description = "Allow SSH access from Jenkins server"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["34.212.198.14/32"] # Replace with Jenkins server's public IP
    //cidr_blocks = [format("%s/32", aws_instance.instance-1.public_ip)] # Replace with Jenkins server's public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prevent Terraform from trying to recreate the security group if it exists
  lifecycle {
    prevent_destroy = true
    ignore_changes = [name, ingress, egress] # Ignore changes to the security group name and rules
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

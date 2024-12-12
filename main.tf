provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "app_ami" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10**"]
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = "masterkey"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
}

resource "aws_security_group" "golden_image_source_sg" {
  name = "golden-image-source-sg"
  description = "Security group for golden image source instance"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your specific IP address range for SSH access (highly recommended)
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic for simplicity (adjust based on your needs)
  }
}

resource "aws_instance" "golden_image_source" {
  ami = data.aws_ami.app_ami.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.id

  vpc_security_group_ids = [aws_security_group.golden_image_source_sg.id]

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install httpd -y",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("/var/lib/jenkins/.ssh/id_rsa")
      host = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.golden_image_source.private_ip} >> private_ips.txt"
  }

  tags = {
    Name = "Ec2-Instance"
  }
}

output "mypublicIP" {
  value = aws_instance.golden_image_source.public_ip
}

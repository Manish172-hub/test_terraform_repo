data "aws_ami" "app_ami" {
  owners      = ["amazon"]
  most_recent = true


  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10**"]
  }
}
resource "aws_instance" "instance-1" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mykey.key_name

  provisioner "remote-exec" {
    inline = [
     "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl start nginx"
    ]
    
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/var/lib/jenkins/.ssh/id_rsa")   //private key path
    //host        = self.public_ip
    host = "54.149.118.30"
  }
  provisioner "local-exec" {
    #command = "echo ${aws_instance.instance-1.private_ip} >> private_ips.txt"
    command = "echo ${aws_instance.instance-1.private_ip} >> private_ips.txt"
  }
  
   provisioner "local-exec" {
    command = "cat /dev/null>private_ips.txt"
    when = destroy
  }
}
output "mypublicIP" {
  value = aws_instance.instance-1.public_ip
}
resource "aws_key_pair" "mykey" {
  key_name   = "myfusionkey"
  //public_key = file("${path.module}/id_ed25519.pub")
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")   //key for ec2 on created on jenkins user and share path
}


provider "aws" {
  region  = "us-west-2" # Replace with your desired region
  profile = "default"   # Optional, replace with your AWS CLI profile
}
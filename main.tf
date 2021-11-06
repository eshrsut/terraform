terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.64.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  # Configuration options
  region = "ap-south-1"

}


# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  }



#AWS internet gatewa
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}


#aws internet gateway
resource "aws_route" "myigroute" {
  route_table_id         = aws_vpc.myvpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myigw.id
}

#aws subnet
resource "aws_subnet" "mysubnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/16"
  map_public_ip_on_launch = true
}


# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "mysg-db" {
  name        = "terraform_example_db"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.myvpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "mysg-web" {
  name        = "mysecurity group"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.myvpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#key pair 
resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7TvnIIBlo6l8C2bOZ2yvPXQX5Rj8zx2s6AfHXB+4J/QC8+keRHH6XgEia4KwRGvzvpFnh0Yr5OtiNJAFZVXf0idpI7zcu+C3BdNPJn92W5PmlsZq0F+k+3yHu3TRoQC+qug2ksxkIT73Kav3mPhZQeuVAMogHJfbHFWplLvNJa7CD18QzoHf/g+c94p16eggO1Ge0DZFyTyAxAythCWgLjt6TnJJrNbplK5G7ciafMpjOQJqAVOdHPvEyEYld3oYRvk8yf3DtgIfBCVJ0pl7ljsdIrcUwScr7D2KEj3XzZqFv1s3x3OascxKlRhrSYmE93Kr5jytb2sjAH2qBWvBwEyH0fxu4VTKLtNhPaD+CFdr+9eWXPcIJNq6CU74WizQ7q4X+vvkat5CkU5tO1NrDuCl3Fi2U788qzD8GdQrDP6t3tGVh5GGZTb/Ba6O+gu8DcoZxhdGLGiu+v+D3OKS4jGBi4vvoyoXXNVL5PCKHnTcGyRikOPBtsGZ2hdU3Ap0= Shriram@DESKTOP-3E4VEHT"
}

data "template_file" "user_data" {
  template = file("./userdata.yml")
}

resource "aws_instance" "myweb" {
  ami           = "ami-041db4a969fe3eb68"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.key_name
  user_data = data.template_file.user_data.rendered
  vpc_security_group_ids = [aws_security_group.mysg-web.id]
  subnet_id = aws_subnet.mysubnet1.id
  tags = {
    Name = "HelloWorld"
  }
}
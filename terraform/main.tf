# Terraform AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 1️⃣ Create VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyTerraformVPC"
  }
}

# 2️⃣ Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "MyPublicSubnet"
  }
}

# 3️⃣ Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MyIGW"
  }
}

# 4️⃣ Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "MyPublicRouteTable"
  }
}

# 5️⃣ Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6️⃣ Security Group (Allow SSH & HTTP)
resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

# 7️⃣ Ubuntu EC2 Instance (using existing key pair)
resource "aws_instance" "ubuntu" {
  ami                    = "ami-0360c520857e3138f" # ✅ Ubuntu AMI (your choice)
  instance_type          = "t3.micro"              # ✅ Instance type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "shanthipem"    # ✅ Existing AWS Key Pair

  tags = {
    Name = "UbuntuServer"
  }
}

# 8️⃣ Output public IP for SSH
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.ubuntu.public_ip
}

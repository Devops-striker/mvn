# This is main.tf
provider "aws" {
  region = "us-east-1"
}

# 1. VPC
resource "aws_vpc" "qa_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "qa_vpc"
  }
}

# 2. Subnet
resource "aws_subnet" "qa_public" {
  vpc_id            = aws_vpc.qa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "qa_public"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "qa_igw" {
  vpc_id = aws_vpc.qa_vpc.id
  tags = {
    Name = "qa_igw"
  }
}

# 4. Route Table + Association
resource "aws_route_table" "qa_rt" {
  vpc_id = aws_vpc.qa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.qa_igw.id
  }

  tags = {
    Name = "qa_rt"
  }
}

resource "aws_route_table_association" "qa_rta" {
  subnet_id      = aws_subnet.qa_public.id
  route_table_id = aws_route_table.qa_rt.id
}

# 5. Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.qa_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
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
    Name = "web-sg"
  }
}

# 6. EC2 Instance with Tomcat & Java Installation
# Replace with your actual IAM instance profile name

resource "aws_instance" "web_server" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.qa_public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install java-openjdk11 -y
              yum install -y tomcat
              systemctl start tomcat
              systemctl enable tomcat
              EOF

  tags = {
    Name = "Tomcat-EC2"
  }
}

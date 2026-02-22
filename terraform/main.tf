############################################
# Generate SSH Key
############################################

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "pubjenkins"
  public_key = tls_private_key.generated.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "pubjenkins.pem"
  file_permission = "0400"
}

############################################
# Get Available Availability Zones
############################################

data "aws_availability_zones" "available" {}

############################################
# VPC
############################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tobacco-vpc"
  }
}

############################################
# Subnets (2 Different AZs)
############################################

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "public-subnet-2"
  }
}

############################################
# Internet Gateway
############################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

############################################
# Route Table
############################################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public1_assoc" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public2_assoc" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# Security Group
############################################

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # App access
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # SSH (learning only)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################################
# EC2 Instance
############################################

resource "aws_instance" "backend" {
  ami                    = "ami-0f22858d8bf9b4ebe"   # Amazon Linux 2 (verify latest)
  instance_type          = "t3.micro"               # Free Tier eligible
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = aws_key_pair.generated_key.key_name

  tags = {
    Name = "backend-server"
  }
}

############################################
# RDS Subnet Group
############################################

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "tobacco-db-subnet-group"

  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}

############################################
# RDS MySQL
############################################

resource "aws_db_instance" "mysql" {
  identifier              = "tobacco-mysql"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "Password123!"
  db_name                 = "tobacco_store"
  skip_final_snapshot     = true
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.backend_sg.id]
}
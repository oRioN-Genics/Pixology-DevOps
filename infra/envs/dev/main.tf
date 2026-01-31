locals {
  project = "pixology"
  env     = "dev"
  region  = "ap-south-1"
}

# --- Networking (public VPC) ---

resource "aws_vpc" "this" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.project}-${local.env}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.project}-${local.env}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.project}-${local.env}-public-a"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.project}-${local.env}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# --- Security Group ---

resource "aws_security_group" "web" {
  name        = "${local.project}-${local.env}-web-sg"
  description = "Web + SSH"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (restricted to my IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["123.231.84.196/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project}-${local.env}-web-sg"
  }
}

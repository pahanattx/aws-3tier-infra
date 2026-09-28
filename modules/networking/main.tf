resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "3tier-prod-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-prod-igw"
  }
}

# -------------------------
# Public Subnets
# -------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false

  tags = {
    Name = "3tier-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = false

  tags = {
    Name = "3tier-public-b"
    Tier = "public"
  }
}

# -------------------------
# Private Web Subnets
# -------------------------

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_a_cidr
  availability_zone = var.az_a

  tags = {
    Name = "3tier-private-web-a"
    Tier = "web"
  }
}

resource "aws_subnet" "web_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.web_b_cidr
  availability_zone = var.az_b

  tags = {
    Name = "3tier-private-web-b"
    Tier = "web"
  }
}

# -------------------------
# Private App Subnets
# -------------------------

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_a_cidr
  availability_zone = var.az_a

  tags = {
    Name = "3tier-private-app-a"
    Tier = "app"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_b_cidr
  availability_zone = var.az_b

  tags = {
    Name = "3tier-private-app-b"
    Tier = "app"
  }
}

# -------------------------
# Private Database Subnets
# -------------------------

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_a_cidr
  availability_zone = var.az_a

  tags = {
    Name = "3tier-private-db-a"
    Tier = "database"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_b_cidr
  availability_zone = var.az_b

  tags = {
    Name = "3tier-private-db-b"
    Tier = "database"
  }
}

# -------------------------
# NAT Gateways
# -------------------------

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "3tier-nat-eip-a"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "3tier-nat-eip-b"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "3tier-nat-a"
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "3tier-nat-b"
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "3tier-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Web Tier Route Tables
# -------------------------

resource "aws_route_table" "web_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "3tier-web-a-rt"
  }
}

resource "aws_route_table" "web_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "3tier-web-b-rt"
  }
}

resource "aws_route_table_association" "web_a" {
  subnet_id      = aws_subnet.web_a.id
  route_table_id = aws_route_table.web_a.id
}

resource "aws_route_table_association" "web_b" {
  subnet_id      = aws_subnet.web_b.id
  route_table_id = aws_route_table.web_b.id
}

# -------------------------
# App Tier Route Tables
# -------------------------

resource "aws_route_table" "app_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "3tier-app-a-rt"
  }
}

resource "aws_route_table" "app_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "3tier-app-b-rt"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.app_a.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.app_b.id
}

# -------------------------
# Isolated DB Route Tables
# No default internet route
# -------------------------

resource "aws_route_table" "db_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-db-a-rt"
  }
}

resource "aws_route_table" "db_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "3tier-db-b-rt"
  }
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db_a.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db_b.id
}
#1. Recupero dinamico delle Zone di Disponibilità (AZ)
data "aws_availability_zones" "available" {
  state = "available"
}

#2. Creazione della VPC (Il tuo Data Center virtuale privato)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "portfolio-vpc"
  }
}

#3. Creazione dell'Internet Gateway (La porta d'ingresso/uscita per Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "portfolio-igw"
  }
}

# SUBNET PUBBLICHE (Per ALB e NAT Gateway)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# SUBNET PRIVATE APP per EC2
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-app-subnet-1"
  }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-app-subnet-2"
  }
}

# SUBNET PRIVATE DB (Per il database RDS, totalmente isolate)
resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-db-subnet-1"
  }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-db-subnet-2"
  }
}

#  NAT GATEWAY (Per far uscire su Internet le macchine private)
# 1. IP Pubblico Statico (Elastic IP) per il NAT
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "portfolio-nat-eip"
  }
}

# 2. NAT Gateway posizionato nella Subnet Pubblica 1
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "portfolio-nat-gw"
  }

  # Il NAT ha bisogno che l'Internet Gateway esista prima di essere creato
  depends_on = [aws_internet_gateway.igw]
}

# ROUTE TABLES

# 1. Tabella di Routing PUBBLICA (Usa l'Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                 # Qualsiasi destinazione su Internet
    gateway_id = aws_internet_gateway.igw.id # viene inviata all'Internet Gateway
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associazione: Le due Subnet Pubbliche usano la Tabella Pubblica
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# 2. Tabella di Routing PRIVATA APP (Usa il NAT Gateway)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"            # Qualsiasi destinazione su Internet
    nat_gateway_id = aws_nat_gateway.nat.id # viene inviata al NAT Gateway (niente traffico in entrata)
  }

  tags = {
    Name = "private-app-route-table"
  }
}

# Associazione: Le due Subnet Private App usano la Tabella Privata App
resource "aws_route_table_association" "private_app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_app.id
}
resource "aws_route_table_association" "private_app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_app.id
}

# 3. Tabella di Routing PRIVATA DB (Nessun accesso a Internet)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  # Nessun blocco "route" verso l'esterno! Le macchine si parlano solo in locale.

  tags = {
    Name = "private-db-route-table"
  }
}

# Associazione: Le due Subnet Private DB usano la Tabella Privata DB isolata
resource "aws_route_table_association" "private_db_1" {
  subnet_id      = aws_subnet.private_db_1.id
  route_table_id = aws_route_table.private_db.id
}
resource "aws_route_table_association" "private_db_2" {
  subnet_id      = aws_subnet.private_db_2.id
  route_table_id = aws_route_table.private_db.id
}
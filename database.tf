# 1. DB Subnet Group (Raggruppamento delle subnet isolate per il database)
resource "aws_db_subnet_group" "main" {
  name       = "portfolio-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id] # Le due subnet isolate per il database RDS per Multi-AZ

  description = "Subnet group per RDS isolato"

  tags = {
    Name = "portfolio-db-subnet-group"
  }
}

# 2. Istanza Database RDS
resource "aws_db_instance" "main" {
  identifier             = "portfolio-database"
  engine                 = "mysql"
  engine_version         = "8.0"               # Versione stabile di MySQL
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"

  # Credenziali passate in modo sicuro tramite le variabili
  username               = var.db_username
  password               = var.db_password

  # Networking e Sicurezza
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # Assegno il SG creato appositamente
  publicly_accessible    = false                          # Divieto di accesso da Internet

  # Specifiche richieste per Free Tier e Sicurezza
  multi_az               = false               # Disattivato per risparmiare
  storage_encrypted      = true                # Archiviazione crittografata

  # Per progetto di test: Salta il backup finale quando distruggo l'infrastruttura
  skip_final_snapshot    = true

  tags = {
    Name = "portfolio-rds-mysql"
  }
}

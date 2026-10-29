# 1. Security Group per il Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "portfolio-alb-sg"
  description = "Permette traffico HTTP in ingresso da Internet"
  vpc_id      = aws_vpc.main.id

  # Regola in Entrata (Inbound)
  ingress {
    description = "HTTP da Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 = "tutto il mondo"
  }

  # Regola in Uscita (Outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = "tutti i protocolli"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# 2. Security Group per le Istanze EC2 (Server Web)
resource "aws_security_group" "ec2_sg" {
  name        = "portfolio-ec2-sg"
  description = "Permette traffico HTTP solo dal Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP dal Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    # Non uso un IP, ma l'ID del Security Group dell'ALB
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# 3. Security Group per RDS
resource "aws_security_group" "rds_sg" {
  name        = "portfolio-rds-sg"
  description = "Permette traffico MySQL solo dalle EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL dalle istanze EC2"
    from_port       = 3306 # Porta standard di MySQL
    to_port         = 3306 # Porta standard di MySQL
    protocol        = "tcp" # Utilizzo il protocollo TCP per MySQL
    # Il DB accetta connessioni solo dalle macchine che hanno il Security Group delle EC2
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}
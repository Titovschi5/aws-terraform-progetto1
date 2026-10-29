variable "aws_region" {
  description = "La regione AWS dove creare le risorse"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "Il blocco CIDR principale della VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Username amministratore per il database RDS"
  type        = string
}

variable "db_password" {
  description = "Password amministratore per il database RDS"
  type        = string
  sensitive   = true
}

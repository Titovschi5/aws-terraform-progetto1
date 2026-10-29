# restiuisce l'URL pubblico del Load Balancer e l'indirizzo di connessione interno del database RDS
output "alb_dns_name" {
  description = "L'URL pubblico del Load Balancer per accedere al sito web"
  value       = aws_lb.app_lb.dns_name
}

output "rds_endpoint" {
  description = "L'indirizzo di connessione interno del database RDS"
  value       = aws_db_instance.main.endpoint
}

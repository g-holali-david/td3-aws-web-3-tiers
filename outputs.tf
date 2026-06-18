output "site_url" {
  description = "URL publique du site (ALB public)"
  value       = "http://${aws_lb.public.dns_name}"
}

output "rds_endpoint" {
  description = "Endpoint du RDS partage (td-ipssi-rds-v2)"
  value       = data.aws_db_instance.shared.address
}

output "internal_alb_dns" {
  description = "DNS de l'ALB interne (debug)"
  value       = aws_lb.internal.dns_name
}

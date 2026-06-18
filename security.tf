# Chaine du moindre privilege (§4.4) : chaque couche n'accepte le trafic
# QUE de la couche situee juste au-dessus d'elle.

resource "aws_security_group" "alb_public" {
  name   = "td-sg-alb-public"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name   = "td-sg-web"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTP depuis l'ALB public uniquement"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_internal" {
  name   = "td-sg-alb-internal"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTP depuis le tier web uniquement"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name   = "td-sg-app"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTP depuis l'ALB interne uniquement"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NB : pas de SG "rds" ici — le RDS est PARTAGE et gere ailleurs (td-ipssi-rds-v2).
# Son propre Security Group controle l'acces 5432 ; il est publiquement accessible,
# donc nos EC2 app le joignent via leur sortie NAT. La chaine du moindre privilege
# que NOUS gerons s'arrete au tier app (alb-public -> web -> alb-internal -> app).

# Chaine du moindre privilege (§4.4) : chaque couche n'accepte le trafic
# QUE de la couche situee juste au-dessus d'elle.

resource "aws_security_group" "alb_public" {
  name   = "${var.name_prefix}-sg-alb-public"
  vpc_id = data.aws_vpc.default.id

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
  name   = "${var.name_prefix}-sg-web"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "HTTP depuis ALB public uniquement"
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
  name   = "${var.name_prefix}-sg-alb-internal"
  vpc_id = data.aws_vpc.default.id

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
  name   = "${var.name_prefix}-sg-app"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "HTTP depuis ALB interne uniquement"
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
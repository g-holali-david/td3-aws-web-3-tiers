# AMI Amazon Linux 2023 (partagee par les tiers app et web)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# --- ALB INTERNE (entre le tier web et le tier app) ---
resource "aws_lb" "internal" {
  name               = "td-alb-internal"
  internal           = true # ALB INTERNE : IP privees uniquement
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = aws_subnet.app[*].id # subnets prives "app"
}

resource "aws_lb_target_group" "app" {
  name     = "td-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- Instances du tier APP (une par AZ) ---
resource "aws_instance" "app" {
  count                  = length(var.azs)
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.app[count.index].id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/app/user_data.sh.tpl", {
    db_host     = data.aws_db_instance.shared.address
    db_name     = local.rds_creds.db_name
    db_user     = local.rds_creds.username
    db_password = local.rds_creds.password
    app_code    = file("${path.module}/app/app.py")
  })

  tags = { Name = "td-app-${count.index}" }
}

# Rattacher chaque instance "app" au target group "app"
resource "aws_lb_target_group_attachment" "app" {
  count            = length(var.azs)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

# Compte verrouille : creation de VPC interdite (ec2:CreateVpc deny).
# => on DEPLOIE dans le VPC par defaut existant (lecture via data source),
#    comme l'attend le prof. On y cree nos propres subnets + NAT + routes.

data "aws_vpc" "default" {
  default = true # VPC par defaut (172.31.0.0/16), celui du RDS partage
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Subnets PUBLICS (un par AZ) ---
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.default.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-${count.index}" }
}

# --- Subnets PRIVES web (un par AZ) ---
resource "aws_subnet" "web" {
  count             = length(var.azs)
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.web_subnet_cidrs[count.index]
  tags              = { Name = "${var.name_prefix}-web-${count.index}" }
}

# --- Subnets PRIVES app (un par AZ) ---
resource "aws_subnet" "app" {
  count             = length(var.azs)
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.app_subnet_cidrs[count.index]
  tags              = { Name = "${var.name_prefix}-app-${count.index}" }
}

# --- NAT Gateway (une par AZ : haute dispo, cf. Question 1) ---
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"
  tags   = { Name = "${var.name_prefix}-eip-nat-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "${var.name_prefix}-nat-${count.index}" }
}

# --- Table de routage PUBLIQUE (-> IGW existante) ---
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }
  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Tables de routage PRIVEES (une par AZ -> NAT de la meme AZ) ---
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "${var.name_prefix}-rt-private-${count.index}" }
}

resource "aws_route_table_association" "web" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

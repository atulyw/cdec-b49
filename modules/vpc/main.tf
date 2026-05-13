resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(var.tags, {
    Name = "${var.application}-vpc-${var.env}"
    Env  = var.env
    }
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet)
  vpc_id            = aws_vpc.this.id
  availability_zone = element(var.availabilityzone, count.index)
  cidr_block        = var.private_subnet[count.index]
  tags = merge(var.tags, {
    Name = "${var.application}-private-subnet-${var.env}"
    Env  = var.env
    }
  )
}


resource "aws_subnet" "public" {
  count      = length(var.public_subnet)
  vpc_id     = aws_vpc.this.id
  cidr_block = var.public_subnet[count.index]
  tags = merge(var.tags, {
    Name = "${var.application}-public-subnet-${var.env}"
    Env  = var.env
    }
  )
}


resource "aws_route_table" "main" {
  vpc_id = aws_vpc.this.id
  route  = []
  tags = merge(var.tags, {
    Name = "${var.application}-main-rt-${var.env}"
    Env  = var.env
    })
}

resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.this.id
  route  = []
  tags = merge(var.tags, {
    Name = "${var.application}-nat-rt-${var.env}"
    Env  = var.env
    })
}



resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.nat.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

 tags = merge(var.tags, {
    Name = "${var.application}-igw-${var.env}"
    Env  = var.env
    })
}    

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}


resource "aws_eip" "this" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public[0].id
  tags = merge(var.tags, {
    Name = "${var.application}-nat-gateway-${var.env}"
    Env  = var.env
    })
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}
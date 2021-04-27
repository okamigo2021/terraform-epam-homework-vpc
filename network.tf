resource "aws_vpc" "web_vpc" {
  cidr_block         = "192.168.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "web_vpc"
  }
}

#provision webserver subnet
resource "aws_subnet" "web_subnet1" {
  vpc_id            = aws_vpc.web_vpc.id
  availability_zone = "us-east-2a"
  cidr_block        = "192.168.20.0/24"
  tags = {
    Name = "web_subnet1"
  }
}

#create Internet Gateway
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.web_vpc.id
}

#provision public subnet 1
resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "192.168.10.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "public_subnet1"
  }
}

#provision public subnet 1
resource "aws_subnet" "public_subnet2" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "192.168.11.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "public_subnet2"
  }
}

#provision database subnet #1
resource "aws_subnet" "db_subnet1" {
  vpc_id     = aws_vpc.web_vpc.id
  cidr_block = "192.168.30.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "database subnet 1"
  }
}

#provision database subnet #2
resource "aws_subnet" "db_subnet2" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "192.168.31.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "database subnet 2"
  }
}

#make db subnet group 
resource "aws_db_subnet_group" "dbsubnet" {
  name       = "main"
  subnet_ids = [aws_subnet.db_subnet1.id, aws_subnet.db_subnet2.id]
}

 #new default route table 
resource "aws_default_route_table" "default" {
   default_route_table_id = "${aws_vpc.web_vpc.default_route_table_id}"

   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.app_igw.id}"
   }
}

# provision Elastic IP for nat gateway 1
resource "aws_eip" "gwip1" {
}

# NAT Gateway for Web subnet 1 (to pull packages, docker, etc)
resource "aws_nat_gateway" "gw1" {
  allocation_id = aws_eip.gwip1.id
  subnet_id = aws_subnet.public_subnet1.id
  tags = {
    Name = "Wordpress TF NAT Gateway 1"
  }
}

resource "aws_route_table" "natroute1" {
  vpc_id = "${aws_vpc.web_vpc.id}"
   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_nat_gateway.gw1.id}"
   }
}

resource "aws_route_table_association" "a" { 
  subnet_id = "${aws_subnet.web_subnet1.id}"
  route_table_id = "${aws_route_table.natroute1.id}"
}
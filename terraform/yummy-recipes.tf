variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "domain_name" {}

data "aws_availability_zones" "available" {}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "us-east-1"
}

resource "aws_vpc" "yummy-recipes" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "yummy-recipes"
  }
}

resource "aws_subnet" "frontend-1a" {
  vpc_id     = "${aws_vpc.yummy-recipes.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "frontend-1a"
  }
}

resource "aws_subnet" "frontend-1b" {
  vpc_id     = "${aws_vpc.yummy-recipes.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "frontend-1b"
  }
}

resource "aws_subnet" "api-1a" {
  vpc_id     = "${aws_vpc.yummy-recipes.id}"
  cidr_block = "10.0.51.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "api-1a"
  }
}

resource "aws_subnet" "api-1b" {
  vpc_id     = "${aws_vpc.yummy-recipes.id}"
  cidr_block = "10.0.52.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "api-1b"
  }
}

resource "aws_subnet" "db" {
  vpc_id     = "${aws_vpc.yummy-recipes.id}"
  cidr_block = "10.0.200.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "db"
  }
}

resource "aws_internet_gateway" "yummy-recipes-igw" {
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  tags {
    Name = "yummy-recipes-igw"
  }
}

resource "aws_security_group" "frontend-sg" {
  name        = "frontend-sg"
  description = "Allow world to access frontend"
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["41.212.110.20/32"]
  }

  tags {
    Name = "frontend-sg"
  }
}

resource "aws_security_group" "api-sg" {
  name        = "api-sg"
  description = "Allow internal connections"
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags {
    Name = "api-sg"
  }
}

resource "aws_security_group" "nat-sg" {
  name        = "nat-sg"
  description = "Allow api"
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["41.212.110.20/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.52.0/24", "10.0.51.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.52.0/24", "10.0.51.0/24"]
  }

  tags {
    Name = "nat-sg"
  }
}

resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Allow api to connect with db"
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["41.212.110.20/32"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.52.0/24", "10.0.51.0/24"]
  }

  tags {
    Name = "db-sg"
  }
}

resource "aws_route53_zone" "primary" {
  name = "${var.domain_name}"
}

/*
resource "aws_instance" "yummy-recipes-NAT" {
  ami           = "ami-6871a115"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.nat-sg.id}"]
  subnet_id = "${aws_subnet.frontend-1a.id}"
  source_dest_check = false
  key_name = "${var.key_name}"

  connection {
    user     = "ec2-user"
    private_key = "${var.private_key_path}"
  }

  provisioner "remote-exec" {
    script = "nat-config.sh"
  }

  tags {
    Name = "NAT"
  }
}
*/

resource "aws_eip" "nat-eip" {
}
resource "aws_nat_gateway" "yummy-recipes-nat" {
  allocation_id = "${aws_eip.nat-eip.id}"
  subnet_id     = "${aws_subnet.frontend-1a.id}"
}

/*
resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "main"
  subnet_ids = ["${aws_subnet.frontend.id}", "${aws_subnet.backend.id}"]

  tags {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "db-instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgresql"
  engine_version       = "9.6.6-R1"
  db_subnet_group_name = "${module.vpc.aws_db_subnet_group_database}"
  instance_class       = "db.t2.micro"
  name                 = "yummy-recipes-db"
  username             = "yummy-recipes"
  password             = "abcd1234"
  parameter_group_name = "default.mysql5.7"
}
*/

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.yummy-recipes.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.yummy-recipes-igw.id}"
  }

  tags {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public-rt1" {
  subnet_id      = "${aws_subnet.frontend-1a.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}
resource "aws_route_table_association" "public-rt2" {
  subnet_id      = "${aws_subnet.frontend-1b.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_default_route_table" "private-rt" {
  default_route_table_id = "${aws_vpc.yummy-recipes.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.yummy-recipes-nat.id}"
  }

  tags {
    Name = "private table"
  }
}

data "aws_ami" "api_ami" {
  most_recent      = true

  filter {
    name   = "name"
    values = ["yummy-recipes-api*"]
  }
}

data "aws_ami" "frontend_ami" {
  most_recent      = true

  filter {
    name   = "tag:name"
    values = ["yummy-recipes-frontend*"]
  }
}

resource "aws_instance" "yummy-recipes-frontend-1a" {
  ami           = "${data.aws_ami.frontend_ami.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.frontend-sg.id}"]
  subnet_id = "${aws_subnet.frontend-1a.id}"
  associate_public_ip_address = true

  #creates ssh connection to consul servers
  connection {
    user = "ubuntu"
    private_key="${file(var.private_key_path)}"
    /*agent = true
    timeout = "3m"*/
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh ${var.domain_name}",
    ]
  }

  tags {
    Name = "yummy-recipes-frontend-1b"
  }

  tags {
    Name = "yummy-recipes-frontend-1a"
  }
}

resource "aws_instance" "yummy-recipes-frontend-1b" {
  ami           = "${data.aws_ami.frontend_ami.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.frontend-sg.id}"]
  subnet_id = "${aws_subnet.frontend-1b.id}"
  associate_public_ip_address = true

  #creates ssh connection to consul servers
  connection {
    user = "ubuntu"
    private_key="${file(var.private_key_path)}"
    /*agent = true
    timeout = "3m"*/
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh ${var.domain_name}",
    ]
  }

  tags {
    Name = "yummy-recipes-frontend-1b"
  }
}

resource "aws_lb_target_group" "frontend-tg" {
  name     = "frontend-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.yummy-recipes.id}"
  health_check {
    port = 80
    path = "/"
    matcher = 200
  }
  tags {
    name = "frontend-lb"
  }
}

resource "aws_lb_target_group_attachment" "frontend-tg-att1" {
  target_group_arn = "${aws_lb_target_group.frontend-tg.arn}"
  target_id        = "${aws_instance.yummy-recipes-frontend-1a.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "frontend-tg-att2" {
  target_group_arn = "${aws_lb_target_group.frontend-tg.arn}"
  target_id        = "${aws_instance.yummy-recipes-frontend-1b.id}"
  port             = 80
}

resource "aws_lb" "frontend-lb" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.frontend-sg.id}"]
  subnets            = ["${aws_subnet.frontend-1a.id}", "${aws_subnet.frontend-1b.id}"]

  tags {
    name = "frontend-lb"
  }
}

/*resource "aws_lb_listener" "frontend-lb-listener1" {
  load_balancer_arn = "${aws_lb.frontend-lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate_validation.cert.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.frontend-tg.arn}"
    type             = "forward"
  }
}*/

resource "aws_lb_listener" "frontend-lb-listener2" {
  load_balancer_arn = "${aws_lb.frontend-lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.frontend-tg.arn}"
    type             = "forward"
  }
}

resource "aws_route53_record" "frontend-record" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "www"
  type    = "CNAME"
  ttl     = "300"

  records = ["${aws_lb.frontend-lb.dns_name}"]
}

resource "aws_instance" "yummy-recipes-api-1a" {
  ami           = "${data.aws_ami.api_ami.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.api-sg.id}"]
  subnet_id = "${aws_subnet.api-1a.id}"
  associate_public_ip_address = true

  tags {
    Name = "yummy-recipes-api-1a"
  }
}

resource "aws_instance" "yummy-recipes-api-1b" {
  ami           = "${data.aws_ami.api_ami.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.api-sg.id}"]
  subnet_id = "${aws_subnet.api-1b.id}"
  associate_public_ip_address = true

  tags {
    Name = "yummy-recipes-api-1b"
  }
}

resource "aws_lb_target_group" "api-tg" {
  name     = "api-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.yummy-recipes.id}"
  health_check {
    port = 80
    path = "/"
    matcher = 302
  }
  tags {
    name = "api-lb"
  }
}

resource "aws_lb_target_group_attachment" "api-tg-att1" {
  target_group_arn = "${aws_lb_target_group.api-tg.arn}"
  target_id        = "${aws_instance.yummy-recipes-api-1a.id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "api-tg-att2" {
  target_group_arn = "${aws_lb_target_group.api-tg.arn}"
  target_id        = "${aws_instance.yummy-recipes-api-1b.id}"
  port             = 80
}

resource "aws_lb" "api-lb" {
  name               = "api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.frontend-sg.id}"]
  subnets            = ["${aws_subnet.frontend-1a.id}", "${aws_subnet.frontend-1b.id}"]

  tags {
    name = "api-lb"
  }
}

/*resource "aws_lb_listener" "api-lb-listener1" {
  load_balancer_arn = "${aws_lb.api-lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate_validation.cert.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.api-tg.arn}"
    type             = "forward"
  }
}*/

resource "aws_lb_listener" "api-lb-listener2" {
  load_balancer_arn = "${aws_lb.api-lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.api-tg.arn}"
    type             = "forward"
  }
}

resource "aws_route53_record" "api-record" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = "api"
  type    = "CNAME"
  ttl     = "300"

  records = ["${aws_lb.api-lb.dns_name}"]
}

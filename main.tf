
output "hello_world" {
    value = "Hello,World"
}

provider "aws" {
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
   region     = var.aws_region
}
# bucket
resource "aws_s3_bucket" "onebucket" {
  bucket = "test-prueba-derito"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "Flugel-test"
    Environment = "Dev"
  }
}
# file 1
resource "null_resource" "test1" {
  provisioner "local-exec" {
    command = "date '+%H%M-%d-%m-%Y' >> ${path.module}/test1.txt"
  }
}
# file 2
resource "null_resource" "test2" {
  provisioner "local-exec" {
    command = "date '+%H%M-%d-%m-%Y' >> ${path.module}/test2.txt"
  }
}
# upload files 1/2
resource "aws_s3_bucket_object" "object" {
  for_each = fileset("${path.module}", "*.txt")

  bucket = "test-prueba-derito"
  key    = each.value
  source = "${path.module}/${each.value}"
  etag   = filemd5("${each.value}")
}
# vpc creation
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "Flugel-test"
  }
}

# oublic subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "Flugel-test"
  }
}

resource "aws_subnet" "my_subnet_private" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "Flugel-test"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Flugel-test"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Flugel-test"
  }
}

resource "aws_route_table" "example_private" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Flugel-test"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.my_subnet_private.id
  route_table_id = aws_route_table.example_private.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.example.id
}

resource "aws_network_interface" "one" {
  subnet_id   = aws_subnet.my_subnet_private.id
  private_ips = ["172.16.1.100"]

  tags = {
    Name = "primary_network_interface_one"
  }
}

resource "aws_network_interface" "two" {
  subnet_id   = aws_subnet.my_subnet_private.id
  private_ips = ["172.16.1.101"]

  tags = {
    Name = "primary_network_interface_two"
  }
}


resource "aws_instance" "ec2_flugel_1" {
  ami           = "ami-05e809fbeee38dd5e" 
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.one.id
    device_index         = 0
  }

  tags = {
		Name = "flugel1"
	}

  vpc_security_group_ids = [aws_security_group.instance.id]
}

resource "aws_instance" "ec2_flugel_2" {
  ami           = "ami-05e809fbeee38dd5e" 
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.two.id
    device_index         = 0
  }

  tags = {
		Name = "flugel2"
	}
  
  vpc_security_group_ids = [aws_security_group.instance.id]
}

resource "aws_security_group" "instance" {
	name = "terraform-tcp-security-group"
 
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
 
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "alb_test" {
  name               = "test-flugel"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance.id]
  subnet_mapping {
    subnet_id = aws_subnet.my_subnet.id
  }            

  enable_deletion_protection = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_target_group" "alb_tg" {
 name     = "my-target-group"
 port     = 80
 protocol = "HTTP"
 vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group_attachment" "target_registration" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.ec2_flugel_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target_registration2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.ec2_flugel_2.id
  port             = 80
}

resource "aws_lb_listener" "alb_listener" {
 load_balancer_arn = aws_lb.alb_test.arn
 port              = "80"
 protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

output "alb_dns" {
  value = aws_lb.alb_test.dns_name
}
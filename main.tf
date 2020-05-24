

provider "aws" {
  region = "us-west-1"
}

data "aws_vpc" "default" {
  default = true

}

#attaching the internet gateway to the default VPC
resource "aws_internet_gateway" "internetgateway" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "defaultigw"
  }
}

# create Web Route Table
resource "aws_route_table" "defaultwebroute" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internetgateway.id}"

  }

  tags = {
    Name = "defaultwebroute"
  }
}

data "aws_subnet_ids" "selectedsubnetid" {
    vpc_id = data.aws_vpc.default.id
  filter {
    name   = "tag:Name"
    values = ["Public"]
  }
}


locals{

public_subnetid = join(",",data.aws_subnet_ids.selectedsubnetid.ids)
}
# data "aws_subnet_ids" "allsubnets" {
#   vpc_id = data.aws_vpc.default.id
# }

# data "aws_subnet" "example" {
#   for_each = data.aws_subnet_ids.allsubnets.ids
#   id       = each.value
# }



# Web Route table association
resource "aws_route_table_association" "routeassociation" {
  subnet_id = local.public_subnetid
  route_table_id = aws_route_table.defaultwebroute.id
  
}

resource "aws_instance" "chapter1" {
  ami                    = "ami-06fcc1f0bc2c8943f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  key_name = var.keyname

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y httpd
                sudo systemctl start httpd.service 
                sudo systemctl enable httpd.service
                echo "Hello, World from $(hostname -f)"> /var/www/html/index.html
                EOF
  tags = {
    Name = "webec2"

  }

}
 
resource "aws_security_group" "websg" {
  name = "websg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

output "default_vpc_ip" {
  value = data.aws_vpc.default.id
  description = "The default vpc id"
}

output "internetgw" {
  value = aws_internet_gateway.internetgateway.id
  description = "The public IP address of the web server"
}

output "public_ip" {
  value = aws_instance.chapter1.public_ip
  description = "The public IP address of the web server"
}

output "selected_subnet_id" {
  #value = data.aws_subnet_ids.selectedsubnetid.ids
  description = "The selected subnet to attach the route to"

  value = join(",",data.aws_subnet_ids.selectedsubnetid.ids)
}



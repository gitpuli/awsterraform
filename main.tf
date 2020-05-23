

provider "aws" {
  region = "us-west-1"
}



resource "aws_instance" "chapter1" {
  ami           = "ami-06fcc1f0bc2c8943f"
  instance_type = "t2.micro"

tags = {
Name="webec2"

}

}



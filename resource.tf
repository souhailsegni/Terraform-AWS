resource "aws_vpc" "MY-VPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev"
  }
}
resource "aws_subnet" "MY-VPC-SUBNET" {
  vpc_id                  = aws_vpc.MY-VPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Main"
  }
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.MY-VPC.id

  tags = {
    Name = "IGW"
  }
}
resource "aws_route_table" "RTB" {
  vpc_id = aws_vpc.MY-VPC.id

  tags = {
    Name = "dev-RT"
  }
}
resource "aws_route" "route" {
  route_table_id         = aws_route_table.RTB.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}
resource "aws_route_table_association" "RT-Association" {
  subnet_id      = aws_subnet.MY-VPC-SUBNET.id
  route_table_id = aws_route_table.RTB.id
}
resource "aws_security_group" "sec-grp" {
  name        = "sec-grp"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.MY-VPC.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sec-grp"
  }
}
resource "aws_instance" "web" {
  ami           = data.aws_ami.server-ami.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.keypair.id
  vpc_security_group_ids = [aws_security_group.sec-grp.id]
  subnet_id = aws_subnet.MY-VPC-SUBNET.id
  user_data = file("userdata.tpl")
  provisioner "local-exec" {
  command = templatefile("${var.host_os}_ssh_config.tpl", {
    hostname     = self.public_ip,
    user         = "ubuntu",
    identityfile = "~/.ssh/mykey-pair"
  })
  interpreter = var.host_os == "linux" ? ["bash", "-c"] : ["powershell", "-command"] 
}

  
  tags = {
    Name = "Hello Dev"
  }
 
}
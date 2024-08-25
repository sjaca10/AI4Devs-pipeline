data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "frontend" {
  ami                  = data.aws_ami.latest_amazon_linux.id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile
  tags = {
    Name = "${var.project_name}-frontend"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Timestamp: ${timestamp()}"
              rm -rf /home/ec2-user/*
              cd /home/ec2-user
              aws s3 cp s3://${var.code_bucket}/frontend.zip frontend.zip
              unzip -o frontend.zip
              cd frontend
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              docker build -t frontend .
              docker run -d -p 3000:3000 --name frontend frontend
              EOF

  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
}

resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
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

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}
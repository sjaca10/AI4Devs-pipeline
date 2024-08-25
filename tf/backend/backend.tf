data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "backend" {
  ami                  = data.aws_ami.latest_amazon_linux.id
  instance_type        = "t2.micro"
  iam_instance_profile = var.iam_instance_profile
  tags = {
    Name = "${var.project_name}-backend"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Timestamp: ${timestamp()}"
              rm -rf /home/ec2-user/*
              cd /home/ec2-user
              aws s3 cp s3://${var.code_bucket}/backend.zip backend.zip
              unzip -o backend.zip
              cd backend
              echo 'ec2-user ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/99_ec2-user
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker build -t backend . || { echo 'Docker build failed'; exit 1; }
              sudo docker run -d -p 8080:8080 --name backend backend || { echo 'Docker run failed'; exit 1; }
              EOF

  user_data_replace_on_change = true

  vpc_security_group_ids = [aws_security_group.backend_sg.id]
}

resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
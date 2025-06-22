# Terraform deployment for NailColorizer EC2 App + API Gateway + S3 integration

provider "aws" {
  region = "us-east-1"
}

##############################
# IAM Role for EC2 Instance
##############################
resource "aws_iam_role" "ec2_role" {
  name = "nailcolorizer-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name   = "ec2-s3-access"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.input_bucket.arn}/*",
          "${aws_s3_bucket.output_bucket.arn}/*"
        ]
      }
    ]
  })
}

###########################
# S3 Buckets
###########################
resource "aws_s3_bucket" "input_bucket" {
  bucket = "nailcolorizer-hand-inputs"
  force_destroy = true
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "nailcolorizer-preset-overlays"
  force_destroy = true
}

###########################
# EC2 Instance with User Data
###########################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "nailcolorizer-sg"
  description = "Allow HTTP and SSH"
  ingress = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 8000, to_port = 8000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
  egress = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

resource "aws_instance" "nailcolorizer_ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = file("user_data.sh")

  tags = {
    Name = "nailcolorizer-server"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "nailcolorizer-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

###########################
# API Gateway (HTTP API)
###########################
resource "aws_apigatewayv2_api" "api" {
  name          = "nailcolorizer-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "http_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "http://${aws_instance.nailcolorizer_ec2.public_ip}:8000/recolor"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "recolor_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /recolor"
  target    = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

###########################
# Variables
###########################
variable "key_pair_name" {
  description = "EC2 SSH Key Pair name"
  type        = string
}

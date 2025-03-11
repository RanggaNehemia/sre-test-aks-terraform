terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "aks-bucket-sre-test-prod"
    key    = "terraform/state/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "web" {
  ami           = "ami-0b03299ddb99998e9"
  instance_type = "t2.micro"
  key_name      = "aks-app-key"

  security_groups = ["launch-wizard-1", "ec2-rds-1"]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "SRE-AKS-Instance"
  }
}

resource "aws_db_instance" "rds" {
  identifier           = "aks-production"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t4g.micro"
  username           = "aksadmin"
  password           = var.rds_password
  publicly_accessible = false
  skip_final_snapshot = true
}

resource "aws_s3_bucket" "sre_bucket" {
  bucket = "aks-bucket-${lower(random_id.suffix.hex)}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

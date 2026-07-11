terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "web"{
ami = var.ami_id
instance_type= var.instance_type

tags={
 Name= "gujju-terraform-ec2"
 }
}


resource "aws_s3_bucket" "my_bucket" {
 bucket= var.bucket_name
 
tags = {
 name= "gujju_terraform_s3"
 }
}

variable "region" {
 description = "AWS region to deploy into"
 type = string
 default = "ap-south-1" 
}

variable "ami_id" {
 description = "AMI id for Ec2 instance"
 type = string
}

variable "instance_type" {
 description = "type of Ec2 Instance"
 type = string
 default = "t3.micro"
}

variable "bucket_name" {
 description = "Name of S3 bucket"
 type = string
} 


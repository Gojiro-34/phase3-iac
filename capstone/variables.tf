variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "az_1a" {
  description = "First availability zone"
  type        = string
  default     = "ap-south-1a"
}

variable "az_1b" {
  description = "Second availability zone"
  type        = string
  default     = "ap-south-1b"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name for EC2 SSH access"
  type        = string
  default     = "my-key"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name for the portfolio"
  type        = string
  default     = "gujju-capstone-portfolio-2026"
}

variable "db_password" {
  description = "Master password for RDS. Supplied via terraform.tfvars, never hardcoded or committed."
  type        = string
  sensitive   = true
}

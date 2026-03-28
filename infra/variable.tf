variable "image_uri" {
  type        = string
  default     = "911167917923.dkr.ecr.ca-central-1.amazonaws.com/flask-app:47b75791"
  description = "Enter Your App Image ID"
}

variable "app_name" {
  type        = string
  default     = "flask-app"
  description = "Enter Your App Name"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-0d5d4b0f4e6f895ad"
  description = "Enter Your VPC ID"
}

variable "subnet1a_id" {
  type        = string
  default     = "subnet-05badfe3396ca4402"
  description = "Enter Your Subnet1a ID"
}

variable "subnet1b_id" {
  type        = string
  default     = "subnet-05a218529c1a9dc62"
  description = "Enter Your Subnet1b ID"
}
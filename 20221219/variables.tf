variable "region" {
  type = string
  description = "Region"
  default = "us-west-2"
}

variable "project_cidr" {
    type = string
    description = "CIDR of VPC"
    default = "10.0.0.0/16"
  
}

variable "project_public_subnet" {
  type = list(string)
  description = "Project Public Subnet"
  default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
}

variable "project_private_subnet" {
  type = list(string)
  description = "Project Private Subnet"
  default = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
}

data "aws_availability_zones" "azs" {
  filter {
    name = "group-name"
    values = ["${var.region}"]
  }  
}

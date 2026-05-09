variable "vpc_cidr" {
  type = string
  default = ""
  description = "this variable is for vpc cidr"
}

variable "instance_tenancy" {
  type = string
  default = "default"
  description = "this variable is for instance tenancy"
}

variable "application" {
  type = string
  default = ""
  description = "this variable is for application"
}

variable "environment" {
  type = string
  default = ""
  description = "this variable is for environment"
}

variable "owner" {
  type = string
  default = ""
  description = "this variable is for owner"
}


variable "private_subnet_cidr" {
  type = list(string)
  default = []
  description = "this variable is for private subnet cidr"
}

variable "public_subnet_cidr" {
  type = list(string)
  default = []
  description = "this variable is for private subnet cidr"
}
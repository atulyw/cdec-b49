variable "application" {
  type        = string
  description = "this value is for application name"
}

variable "env" {
  type        = string
  description = "this value is for environment name"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "private_subnet" {
  default = ["10.0.16.0/20", "10.0.48.0/20", "10.0.128.0/20", "10.0.96.0/20"]
  #             0                   1               3               4
}

variable "public_subnet" {
  default = ["10.0.32.0/20"]
}

variable "tags" {
  type = map(string)
  default = {
    owner          = "atul"
    owner-id       = "atulyw@greamio.com"
    bussiness-unit = "112233"
  }
}

variable "availabilityzone" {
  type    = list(string)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  #             0               1               2
}
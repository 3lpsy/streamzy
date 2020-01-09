
variable "project_name" {
  default = "streamzy"
}
variable "aws_access_key_id" {}

variable "aws_secret_access_key" {}

variable "streamer_username" {}

variable "streamer_psk" {}

variable "ami" {
  default = "ami-04b9e92b5572fa0d1" # change me / built via packer
}

variable "instance_type" {
  default = "t3.small" # change me
}

variable "dns_root" {}

variable "dns_sub" {
  default = "stream"
}


variable "trusted_external_cidr_block" {
  type = list(string)
}

variable "internet_cidr_block" {}

variable "aws_default_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.21.0.0/16"
}


//////////////////////////////////
// passed in through command line, do not need defaults
variable "resource_prefix" {
  type = "string"
}

//////////////////////////////////

variable "aws_region" {
  type = "string"
  default = "us-west-2"
}

variable "aws_account_id" {
  type = "string"
  default = ""
}

// there's a reason that these are both named the same thing
provider "aws" {
  region = "${var.aws_region}"
}

provider "aws" {
  # us-east-1 instance for acm certs
  region = "us-east-1"
  alias = "use1"
}

terraform {
  backend "s3" {}
}

# Ubuntu Precise 16.04 LTS (x64)
variable "aws_ami" {
  default = "ami-a58d0dc5"
}


variable "default_security_group_id" {
  type = "string"
  description = "Default security group supports traffic within VPC"
  default = "sg-"
}


variable "subnet_priv_2a" {
  type = "string"
  description = "Private subnet 2a"
  default = "subnet-"
}

variable "subnet_priv_2b" {
  type = "string"
  description = "Private subnet 2b"
  default = "subnet-"
}

variable "subnet_priv_2c" {
  type = "string"
  description = "Private subnet 2c"
  default = "subnet-"
}

variable "public_key_path" {
  default = "./key/key.pem"
}

variable "nginx_confg_file" {
  default = "./config/nginx.conf"
}

variable "proxied_url" {
  default = "example.com"
}

variable "key_name" {
  default = "keyname"
}

variable "env" {
  default = "dev"
}

variable "my_dns" {
  default = "my.dns.com"
}

variable "hosted_zone_id" {
  default = "ZHH3DWKNTVNR3"
}

variable "domain_prefix" {
  default = ""
}
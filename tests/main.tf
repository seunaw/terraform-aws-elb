# @TODO write tests
provider "aws" {
  region = var.region
}

variable "lb_name" {
  default = "terraform-testing-elb"
}
variable "lb_ext_name" {
  default = "terraform-testing-elb-ext"
}
variable "nlb_name" {
  default = "terraform-testing-nlb"
}
variable "nlb_ext_name" {
  default = "terraform-testing-nlb-ext"
}
variable "vpc_id" {
  default = ""
}
variable "region" {
  default = "us-west-2"
}

variable "lb_listener" {
  default = [
    {
      instance_port     = 80
      instance_protocol = "TCP"
      lb_port           = 80
      lb_protocol       = "TCP"
    }
  ]
}

variable "nlb_listener" {
  default = [
    {
      instance_port     = 123
      instance_protocol = "UDP"
      lb_port           = 123
      lb_protocol       = "UDP"
    }
  ]
}

variable "lb_subnets" {
  default = ["subnet-0120e554134068a66", "subnet-0aad6475e58f5245b"]
}

variable "lb_internal" {
  type    = bool
  default = true
}

resource "aws_security_group" "http" {
  name        = "terraform-testing-elb"
  description = "Allow http inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "ntp" {
  name        = "terraform-testing-nlb"
  description = "Allow ntp inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "ntp"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


module "test_lb_internal" {
  source = "../"

  name            = var.lb_name
  subnets         = var.lb_subnets
  security_groups = [aws_security_group.http.id]
  listener        = var.lb_listener
  internal        = var.lb_internal

}

module "test_lb_external" {
  source = "../"

  name            = var.lb_ext_name
  subnets         = var.lb_subnets
  security_groups = [aws_security_group.http.id]
  listener        = var.lb_listener

}

module "test_nlb_internal" {
  source = "../"

  name            = var.nlb_name
  subnets         = var.lb_subnets
  security_groups = []
  listener        = var.nlb_listener
  internal        = var.lb_internal
  network_lb      = true

}

module "test_nlb_external" {
  source = "../"

  name            = var.nlb_ext_name
  subnets         = var.lb_subnets
  security_groups = []
  listener        = var.nlb_listener
  network_lb      = true

}

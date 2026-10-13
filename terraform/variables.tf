variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "eventyx-eks"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "node_instance_type" {
  default = "t3.medium"
}

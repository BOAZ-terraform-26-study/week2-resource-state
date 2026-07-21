variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type = string
}

variable "my_ip" {
  description = "SSH 허용할 본인 공인 IP (curl ifconfig.me). CIDR 아님, 순수 IP."
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro" # 서울 리전 프리티어
}

# 최신 Amazon Linux 2023 AMI (하드코딩 금지)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# TODO(L1): security group — ingress SSH(22)는 "${var.my_ip}/32" 에서만, egress 전체 허용
# resource "aws_security_group" "web" { ... }

# TODO(L1): EC2 인스턴스
#   - ami = data.aws_ami.al2023.id
#   - instance_type = var.instance_type
#   - subnet_id = aws_subnet.public.id
#   - vpc_security_group_ids = [aws_security_group.web.id]
# resource "aws_instance" "web" { ... }

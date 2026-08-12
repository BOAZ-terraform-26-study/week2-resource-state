# TODO(L1): output 3개. 네트워크까지 만든 뒤(A-5) 필요한 것들.  (워크북 A-4)
#   vpc_id     = aws_vpc.main.id
#   subnet_id  = aws_subnet.public.id
#   subnet_az  = aws_subnet.public.availability_zone   # data source가 골라준 AZ 확인용
#   각 output에 description 을 꼭 붙이세요.

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "퍼블릭 서브넷 ID"
  value       = aws_subnet.public.id
}

output "subnet_az" {
  description = "서브넷이 놓인 AZ. data.aws_availability_zones 가 골라준 값"
  value       = aws_subnet.public.availability_zone
}

# TODO(L1): output 3개. EC2까지 만든 뒤(B-1) 필요한 것들.  (워크북 B-1)
#   ami_id             = data.aws_ami.al2023.id     # 옆 사람과 같은 값이 나오는지 비교
#   instance_id        = aws_instance.web.id
#   instance_public_ip = aws_instance.web.public_ip
#
#   주의: instance_public_ip 값은 Discord에 올리지 마세요. 22번이 열린 서버 주소입니다.

output "ami_id" {
  description = "data.aws_ami 가 찾아낸 AL2023 AMI ID"
  value       = data.aws_ami.al2023.id
}

output "instance_id" {
  description = "EC2 인스턴스 ID (destroy 전에 기록해 두면 증빙이 됩니다)"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "자동 할당된 퍼블릭 IPv4. EIP가 아니라서 stop/start 하면 바뀝니다. Discord에 올리지 말 것"
  value       = aws_instance.web.public_ip
}
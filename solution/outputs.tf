output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "퍼블릭 서브넷 ID"
  value       = aws_subnet.public.id
}

output "subnet_az" {
  description = "서브넷이 놓인 AZ — data.aws_availability_zones 가 골라준 값"
  value       = aws_subnet.public.availability_zone
}

output "ami_id" {
  description = "data.aws_ami 가 찾아낸 AL2023 AMI ID"
  value       = data.aws_ami.al2023.id
}

output "instance_id" {
  description = "EC2 인스턴스 ID (destroy 전에 기록해 두면 증빙이 된다)"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "자동 할당된 퍼블릭 IPv4. EIP가 아니므로 stop/start 시 바뀐다. Discord에 올리지 말 것"
  value       = aws_instance.web.public_ip
}

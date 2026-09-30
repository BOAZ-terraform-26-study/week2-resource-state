# TODO(L1): output 3개. 네트워크까지 만든 뒤(A-5) 필요한 것들.  (워크북 A-4)
#   vpc_id     = aws_vpc.main.id
#   subnet_id  = aws_subnet.public.id
#   subnet_az  = aws_subnet.public.availability_zone   # data source가 선택한 AZ 확인용
#   각 output에 description 을 꼭 붙이세요.


# TODO(L1): output 3개. EC2까지 만든 뒤(B-1) 필요한 것들.  (워크북 B-1)
#   ami_id             = data.aws_ami.al2023.id     # 옆 사람과 같은 값이 나오는지 비교
#   instance_id        = aws_instance.web.id
#   instance_public_ip = aws_instance.web.public_ip
#
#   주의: instance_public_ip 값은 Discord에 올리지 마세요. 22번이 열린 서버 주소입니다.

# Week2 실습 — VPC + EC2

## 실행 순서
```bash
cp example.tfvars terraform.tfvars   # project_name, my_ip 수정
terraform init
terraform plan
terraform apply
terraform state list
terraform state show aws_instance.web
terraform destroy    # 반드시!
```

## 난이도 가이드
- L1(필수): network.tf / compute.tf / outputs.tf의 TODO 완성 -> apply -> destroy
- L2: private subnet 추가 (NAT는 금지)
- L3-⭐: user_data로 nginx, 그래프 시각화

## 막히면 여기
1. `aws_subnet`, `aws_route_table`, `aws_security_group`, `aws_instance` 문서
2. 의존성은 명시적 `depends_on` 없이 **참조**(`aws_vpc.main.id`)로 자동 생성됨
3. `../solution/` 참고

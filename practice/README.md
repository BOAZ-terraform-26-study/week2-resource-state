# Week2 실습 — VPC + EC2 배포하고 state 뜯어보기

> 자세한 진행은 **[실습 워크북](../lecture/실습워크북.md)** 을 위에서 아래로 따라가세요. 이 파일은 요약입니다.

## 미션

`network.tf` · `compute.tf` · `outputs.tf`의 `# TODO`를 채워 **리소스 7개**를 만들고, `tfstate`를 뜯어보고, 역순으로 지웁니다.

| 파일 | TODO 개수 | 긋는 화살표 |
|------|----------|-----------|
| `network.tf` | 4개 (subnet / igw / route table / association) | ① ~ ⑦ |
| `compute.tf` | 2개 (security group / EC2) | ⑧ ~ ⑪ |
| `outputs.tf` | 2개 (네트워크 3개 / 컴퓨트 3개) | — |

`versions.tf` · `providers.tf` · `variables.tf`, 그리고 `data "aws_availability_zones"` · `aws_vpc.main` · `data "aws_ami"`는 **이미 채워져 있습니다.** 읽기만 하세요.

## 실행 순서

```bash
cp example.tfvars terraform.tfvars   # project_name, my_ip 수정 (my_ip는 curl -4 ifconfig.me)
terraform init                       # provider 다운로드 (예습에서 미리)

#  network.tf + outputs.tf 첫 TODO 채우고
terraform fmt && terraform validate
terraform plan                       # "Plan: 5 to add"
terraform apply                      # yes -> state list 7줄
terraform graph | grep '\->'         # 화살표 확인

#  compute.tf + outputs.tf 두 번째 TODO 채우고
terraform plan                       # "Plan: 2 to add"
terraform apply                      # yes (EC2는 30~60초, Ctrl+C 금지)

#  state 해부
terraform state list                 # 9줄 = 리소스 7 + data 2
terraform state show aws_instance.web
jq 'keys' terraform.tfstate
jq -r '.resources[] | "\(.type).\(.name)  <-  \(.instances[0].dependencies)"' terraform.tfstate

#  마무리
terraform plan -destroy              # "7 to destroy" — 삭제 순서 먼저 예측해볼 것
terraform destroy                    # 반드시!
terraform state list                 # 빈 출력
bash ../scripts/check-leftover.sh    # 계정 잔존 0 확인
```

## 난이도 가이드

- **L1 (필수)**: TODO 전부 채우고 apply → state 해부 → destroy. 여기까지면 DoD 충족
- **L2**: drift 실습(콘솔에서 태그 변경 → `plan -refresh-only`) · private subnet 추가 (**NAT 금지**)
- **L3-⭐**: `~` vs `-/+` 실험 (plan만, apply 금지) · cycle 재현
- **L4**: `user_data` + `depends_on`, 그래프 시각화

## 막히면 여기 (힌트 단계)

1. 레지스트리 문서 —
   [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) ·
   [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) ·
   [aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) ·
   [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) ·
   [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) ·
   [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
2. 의존성은 `depends_on` 없이 **참조**(`aws_vpc.main.id`)로 자동 생성됩니다. 순서를 적으려 하지 마세요.
3. 자주 나는 에러
   - `my_ip는 1.2.3.4 처럼...` → `terraform.tfvars`의 `my_ip`가 `CHANGE-ME`거나 `/32`가 붙어 있음
   - `Security group ... belong to different networks` → SG에 `vpc_id = aws_vpc.main.id` 누락
   - `Your query returned no results` → 리전이 `ap-northeast-2`가 아님
   - `DependencyViolation` (destroy) → 1~2분 후 `terraform destroy` 재실행
4. 그래도 안 되면 `../solution/` 참고. **막혀서 못 만든 사람도 destroy 사이클은 반드시 닫으세요.**

# Week 2. 리소스 문법 & State 개념 `[비대면]`

> 이번 주가 끝나면: **VPC·Subnet·EC2를 코드로 배포하고, 리소스 간 의존성과 `tfstate` 구조를 읽을 수 있다.**

## 0. 메타 정보
| 항목 | 내용 |
|------|------|
| 일시 | 2026-MM-DD · 60분 |
| 방식 | 비대면 (Discord) |
| 선행 | week1 완료 · 과제① 제출 |
| 산출물 | 실습 PR + 워크북 (지난 과제 리뷰 O) |

## 1. 학습 목표 (측정 가능)
- [ ] 리소스 참조(`aws_vpc.main.id`)로 생기는 **암묵적 의존성**을 설명할 수 있다
- [ ] `data source`와 `resource`의 차이를 구분할 수 있다
- [ ] VPC-Subnet-IGW-EC2를 배포하고 SSH 접속(선택)까지 확인할 수 있다
- [ ] `terraform state show`로 tfstate 안의 속성을 열어볼 수 있다

## 2. 사전 예습 (필수)
- HashiCorp: [Dependencies](https://developer.hashicorp.com/terraform/tutorials/configuration-language/dependencies) (10분)
- AWS Provider: [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance), [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) 문서 훑기
- 예습 체크: "왜 AMI ID를 하드코딩하면 안 되는지" 말할 수 있다

## 3. 진행 타임박스 (60분)
| 시간 | 구성 | 내용 |
|------|------|------|
| 0~10분 | 회고 | 랜덤 지목 1~2명, 지난주 배운 것 30초 |
| 10~15분 | 과제① 리뷰 | 대표 PR 화면 공유 |
| 15~58분 | 실습 45분 | 네트워크 -> 컴퓨트 순서로 배포, state 열어보기 |
| 58~60분 | 마무리 | 2주차 정리, 3주차 예고 |

## 4. 실습 개요 — VPC + EC2
오늘 만들 것:
```
VPC (10.0.0.0/16)
 └ public subnet (10.0.1.0/24)
    ├ Internet Gateway + Route Table
    └ EC2 t3.micro (Amazon Linux 2023, SG: 내 IP에서만 SSH)
```
```bash
cd practice
terraform init
terraform plan
terraform apply
terraform state list          # 리소스 목록
terraform state show aws_instance.web   # 속성 열어보기
terraform graph               # (선택) 의존성 그래프
terraform destroy             # 반드시!
```

## 5. 체크포인트 (DoD)
- [ ] `apply` 성공, `state list`에 vpc/subnet/igw/route/sg/instance 존재
- [ ] `state show`로 EC2의 private/public IP 확인
- [ ] **`destroy` 완료 & 콘솔에서 EC2·EIP·ENI 잔존 없음 확인**

## 6. 트러블슈팅 FAQ
| 증상 | 원인 | 해결 |
|------|------|------|
| EC2가 안 지워짐 | SG가 ENI에 물림 (의존성) | Terraform이 순서대로 처리하도록 참조로 연결했는지 확인 |
| SSH 접속 안 됨 | SG가 내 IP 아님 | `my_ip`를 현재 공인 IP로 (`curl ifconfig.me`) |
| AMI not found | AMI를 하드코딩 | `data.aws_ami`로 최신 AL2023 조회 |
| 콘솔에 리소스 안 보임 | 리전 불일치 | 콘솔 우상단 "서울" 확인 |

## 7. 심화 도전과제 (Optional ⭐)
- L2: private subnet 추가 (단, NAT Gateway는 **만들지 말 것** — 과금)
- L3-⭐: `user_data`로 부팅 시 nginx 설치, `terraform graph | dot -Tpng` 로 그래프 시각화

## 8. 다음 주 예고 & 준비물
- Week3: Remote Backend — 지금 로컬에 생기는 `tfstate`를 S3 + DynamoDB로 옮기고 잠금 이해
- 예습: 원격 state가 왜 필요한지, `backend "s3"` 블록

---
> ⚠️ **비용 주의**: EC2 t3.micro는 프리티어지만 **안 지우면 과금**됩니다. NAT Gateway/EIP 만들지 마세요. 실습 종료 = `destroy` 필수.
> **공통 규칙**: 자격증명/secret 커밋 금지 · 실습 종료 = `destroy` 완료 확인 · 코드는 PR로

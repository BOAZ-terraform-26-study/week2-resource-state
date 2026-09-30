# Week 2. 리소스 문법 & State

> 📘 **워크북 2종**. 개념 파트는 개념 워크북, 실습 파트는 실습 워크북을 위에서 아래로 따라갑니다.
> - **[개념 워크북 PDF »](./lecture/개념워크북.pdf)** (12분). 참조·의존성 그래프·데이터 소스·tfstate 내부·drift·교체(`-/+`) · [마크다운](./lecture/개념워크북.md)
> - **[실습 워크북 PDF »](./lecture/실습워크북.pdf)** (43분). `practice/`에서 VPC→EC2 apply → state 분석 → destroy · [마크다운](./lecture/실습워크북.md)
>
> *(PDF는 `.md`를 HTML로 바꿔 headless Chrome 인쇄로 생성한 배포본입니다. 빌드 스크립트는 리포에 두지 않았으니, `.md`를 고쳤으면 PDF도 함께 다시 만들어 주세요. 원본은 항상 `.md` 쪽입니다.)*

> 이번 주가 끝나면: **VPC부터 EC2까지 7개를 코드로 배포하고, `tfstate` 안에서 내가 적지 않은 의존성 그래프를 찾아내고, 역순으로 전부 지울 수 있다.**

## 0. 메타 정보
| 항목 | 내용 |
|------|------|
| 일시 | 2026-MM-DD · 60분 |
| 방식 | 비대면 (Discord) |
| 선행 | [week1 IaC 기초](https://github.com/BOAZ-terraform-26-study/week1-iac-basics) 완료 · 과제① 제출 · **각자 개인 AWS 계정** |
| 산출물 | 실습 PR + 관찰 기록 (지난 과제 리뷰 O) |

## 1. 학습 목표 (측정 가능)
- [ ] 리소스 참조(`aws_vpc.main.id`)가 **간선**이 되어 그래프가 만들어지는 과정을 레벨 5단으로 그릴 수 있다
- [ ] `data source`와 `resource`의 차이를 말하고, **AMI·AZ를 하드코딩하면 안 되는 이유**를 셋 이상 댈 수 있다
- [ ] `terraform.tfstate`의 `dependencies` 배열이 어디서 왔는지 설명할 수 있다
- [ ] 콘솔에서 직접 수정한 값(**drift**)을 `plan`으로 탐지하고 되돌릴 수 있다
- [ ] plan에서 `~`와 `-/+`(`# forces replacement`)를 구분할 수 있다
- [ ] `destroy` 후 **계정에 잔존 리소스가 0개**임을 증명할 수 있다

## 2. 사전 예습 (필수)
- HashiCorp: [Create Resource Dependencies](https://developer.hashicorp.com/terraform/tutorials/configuration-language/dependencies) (10분)
- AWS Provider 문서 훑기: [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) · [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) · [aws_ami (data)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)
- 예습 체크: "왜 AMI ID를 하드코딩하면 안 되는지" 한 문장으로 말할 수 있다

> [!IMPORTANT]
> **예습 과제. 세션 3일 전까지 실행하고 결과를 Discord에 올려주세요.** 이를 하지 않으면 세션 중에 실습 시간이 부족해집니다.
>
> **Discord에는 ③④⑤의 결과만 올리세요. ②의 계정번호 12자리는 올리지 않습니다.**
>
> ```bash
> R=ap-northeast-2
> cd practice && terraform init          # ① provider 미리 받아두기 (세션 중 1~3분 절약)
>
> aws sts get-caller-identity --query Account --output text   # ② 자격증명 (성공/실패만 보고, 계정번호는 올리지 말 것)
>
> # ③ EC2 vCPU 쿼터. 2 이상이어야 함. 0이면 증설 요청에 며칠 걸립니다
> aws service-quotas get-service-quota --region $R --service-code ec2 \
>   --quota-code L-1216C47A --query 'Quota.Value' --output text
>
> # ④ VPC 여유. 5 미만이어야 함 (리전당 기본 5개)
> aws ec2 describe-vpcs --region $R --query 'length(Vpcs)' --output text
>
> # ⑤ 권한 dry-run. "DryRunOperation" 이 나오면 통과
> aws ec2 create-vpc --region $R --cidr-block 10.99.0.0/16 --dry-run 2>&1 | tail -1
> ```

## 3. 진행 타임박스 (60분)
| 시간 | 구성 | 내용 |
|------|------|------|
| 0~10분 | 회고 | 무작위로 1~2명 지정, 지난주 배운 것 30초 |
| 10~15분 | 과제① 리뷰 | 대표 PR 화면 공유. **15분 엄수**, 초과분은 Discord 스레드로 |
| 15~27분 | Block A (12분) | 참조 ①~⑦ 잇고 **네트워크 5개** apply |
| 27~47분 | Block B (20분) | 참조 ⑧~⑪ + EC2 apply → **state 분석** → drift |
| 47~58분 | Block C (11분) | destroy + **계정 잔존 점검** |
| 58~60분 | 마무리 | 2주차 정리, 3주차 예고 |

> 개념 파트(12분)는 별도 슬롯이 아니라 `plan`/`apply`가 실행되는 **대기 시간에** 함께 진행합니다.

## 4. 실습 개요. VPC + EC2

리소스 **7개**, 참조 **11개**.

```
VPC (10.0.0.0/16)
 └ public subnet (10.0.1.0/24, AZ는 data source가 선택)
    ├ Internet Gateway + Route Table(0.0.0.0/0) + Association
    └ EC2 t3.micro (Amazon Linux 2023, SG: 내 IP에서만 SSH 22)
```

```bash
cd practice
cp example.tfvars terraform.tfvars   # project_name, my_ip(curl -4 ifconfig.me)
terraform init
terraform plan                       # 네트워크만: "Plan: 5 to add"
terraform apply                      # -> state list 7줄 (리소스 5 + data 2)
#   compute.tf TODO 채운 뒤
terraform plan                       # "Plan: 2 to add"
terraform apply                      # -> state list 9줄 (리소스 7 + data 2)
terraform state show aws_instance.web
jq -r '.resources[] | "\(.type).\(.name) <- \(.instances[0].dependencies)"' terraform.tfstate
terraform destroy                    # "7 destroyed". 반드시!
bash ../scripts/check-leftover.sh    # 계정 잔존 0 확인
```

- `practice/`의 `# TODO`를 채우며 진행합니다. 막히면 `solution/` 참고(스터디 후 공개 권장).
- **오늘 SSH 접속은 하지 않습니다.** 키페어를 만들면 비밀키가 tfstate에 평문으로 남고 `.pem` 파일이 실수로 커밋되는 사고가 발생합니다. 성공 기준은 `instance_state = running` + 퍼블릭 IP 할당입니다.

## 5. 실습 결과 제출. 브랜치 생성 후 PR

실습이 끝나면 **`submissions/{github-id}/` 본인 폴더**에 올려주세요. 리뷰 후 강사가 머지합니다.

```bash
ID=본인-github-id                                      # {github-id} 는 셸이 치환해주지 않습니다

git switch main && git pull
git switch -c "week2/$ID"                              # 예: week2/kdh1834

mkdir -p "submissions/$ID"
cp practice/*.tf practice/example.tfvars "submissions/$ID/"
cp practice/.terraform.lock.hcl          "submissions/$ID/"
# + state-list.txt (destroy 전에 저장한 증빙: 퍼블릭 IP와 ARN의 계정번호 마스킹)
# + observations.md (워크북 [관찰 ✍️] 답안)

git add "submissions/$ID"
git status                                             # tfvars / tfstate / state.json 확인!
git commit -m "week2: $ID 실습 제출"
git push -u origin "week2/$ID"
git restore practice/                                  # 복사 끝난 뒤 스켈레톤 원복
```

그다음 GitHub에서 `week2/{github-id}` → `main` PR을 만들면 됩니다.

> **`practice/`를 직접 고쳐서 올리지 마세요.** 머지하는 순간 다음 사람이 풀 `# TODO` 스켈레톤이 없어집니다.

> **`terraform.tfvars`(내 공인 IP) / `terraform.tfstate` / `state.json`은 절대 커밋 금지.** `.gitignore`로 제외되어 있지만 푸시 전에 `git status`로 한 번 더 확인하세요.

## 6. 체크포인트 (Definition of Done)
- [ ] `apply` 두 번 성공 (`5 added` → `2 added`), `state list` 9줄
- [ ] `state show`로 EC2의 `private_ip` / `public_ip` / `instance_state` 확인
- [ ] **`dependencies` 배열을 열어 의존성 지도와 대조** (이번 주 핵심)
- [ ] drift 실습: 콘솔에서 태그 변경 → `plan`이 되돌리자고 제안하는 것 확인
- [ ] **`destroy` 완료 (`7 destroyed`) & `state list` 빈 출력**
- [ ] **콘솔/스크립트로 EC2·EBS·EIP·NAT·VPC 잔존 0 확인**
- [ ] `git status`로 시크릿·state 커밋 안 됐는지 확인

## 7. 트러블슈팅 FAQ
| 증상 | 원인 | 해결 |
|------|------|------|
| `my_ip는 1.2.3.4 처럼...` | `terraform.tfvars`가 `CHANGE-ME` 그대로거나 `/32`를 붙임 | 순수 IPv4만. `curl -4 ifconfig.me` |
| `var.project_name` 입력하라며 멈춤 | `terraform.tfvars` 미생성 | **Ctrl+C** → `cp example.tfvars terraform.tfvars` |
| `Your query returned no results` | `data.aws_ami` 필터에 일치하는 이미지가 없음 | 리전이 `ap-northeast-2`인지 확인 |
| `Security group sg-xxx and subnet subnet-yyy belong to different networks` | SG에 `vpc_id` 누락 → 기본 VPC에 생성됨 | `vpc_id = aws_vpc.main.id` 추가 |
| `Unsupported: instance type (t2.micro) is not supported in AZ (2b)` | `t2.micro`는 서울 2b·2d에 없음 | `t3.micro` 사용 |
| `VpcLimitExceeded` | 리전당 VPC 기본 5개 초과 | **지난 실습에서 destroy를 안 했다는 신호.** 잔여 VPC 정리 |
| `DependencyViolation` (destroy 시) | ENI 정리 지연 / 콘솔에서 직접 만든 리소스 | **1~2분 후 `terraform destroy` 재실행** (멱등하므로 안전) |
| `Error acquiring the state lock` | 터미널 2개에서 동시 실행, 또는 Ctrl+C로 강제 종료 | 끝날 때까지 대기. `.terraform.tfstate.lock.info` 확인 |
| `Still creating...`에서 멈춘 것 같음 | EC2 생성은 30~60초 걸림 | **정상입니다. Ctrl+C 금지** |
| 콘솔에 아무것도 안 보임 | 리전 불일치 | 콘솔 우상단 "서울" 확인 |

## 8. 심화 도전과제 (Optional ⭐)
- **L2**: private subnet 추가 (단, **NAT Gateway는 만들지 말 것**. 시간당 과금)
- **L3-⭐**: `~` vs `-/+` 실험. subnet `cidr_block`을 한 글자 바꿔 **연쇄 교체 3개**를 plan으로만 확인하고 원복 (워크북 B-6)
- **L3-⭐⭐**: SG 두 개를 서로 참조해 `Error: Cycle:` 재현 후 제거 (워크북 B-7)
- **L4**: `user_data`로 nginx 설치. 그런데 EC2는 route table association을 기다리지 않습니다. `depends_on`이 왜 필요한지 직접 겪어보기
- **L4**: `terraform graph` 출력을 <https://dreampuf.github.io/GraphvizOnline/> 에 붙여 그림으로 보기

## 9. 다음 주 예고 & 준비물
- **Week3: Remote Backend & 잠금**. 오늘 분석한 `tfstate`(`serial`·`lineage`·평문 JSON)가 그대로 문제가 됩니다. S3 + 잠금으로 옮깁니다.
- 예습: 원격 state가 왜 필요한지, `backend "s3"` 블록, `terraform init -migrate-state`

---
> ⚠️ **비용 주의**: 프리티어가 끝난 계정은 **시간당 약 $0.019(약 27원)** 발생합니다(EC2 $0.0130 + 퍼블릭 IPv4 $0.005 + EBS). **43분 실습 = 약 20원, destroy 안 하고 한 달 = 약 2만원.** NAT Gateway·EIP는 만들지 마세요.
> **공통 규칙**: 자격증명/secret 커밋 금지 · 실습 종료 = `destroy` 완료 확인 · 코드는 PR로

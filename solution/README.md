# Week2 정답 코드 + 설계 노트

스터디 종료 후 참고용. 먼저 `practice/`에서 직접 채워보세요.
`terraform init && terraform apply` 후 **반드시 `terraform destroy`.**

---

## 왜 이렇게 썼나 (설계 결정 7개)

### 1. `availability_zone`을 하드코딩하지 않고 데이터 소스로 받는다
```hcl
availability_zone = data.aws_availability_zones.available.names[0]
```
- AZ 이름(`ap-northeast-2a`)은 **계정마다 다른 물리 AZ에 매핑**됩니다. 오래된 계정은 특정 AZ에 서브넷을 못 만들 수도 있습니다.
- **AZ × 인스턴스 타입** 조합 문제: 서울 리전에서 `t3.micro`는 2a/2b/2c/2d 전부 가능하지만 **`t2.micro`는 2b·2d에 없습니다.**
- 부수 효과로 참조 ②가 생겨 "데이터 소스도 그래프의 노드"라는 걸 가르칠 수 있습니다.

### 2. AMI 이름 필터를 `al2023-ami-2023.*` 로 **시작까지** 고정한다
느슨한 `al2023-ami-*-x86_64`로 두면 서울 리전에서 이런 것들이 후보에 섞이고, `most_recent = true`가 그중 가장 최근 것을 고릅니다.

| 걸리는 AMI | 루트 볼륨 | 문제 |
|-----------|----------|------|
| `al2023-ami-ecs-neuron-hvm-*` | **30 GiB** | ECS 전용. 실제로 이게 뽑힙니다 |
| `al2023-ami-ecs-hvm-*` | 30 GiB | ECS 전용 |
| `al2023-ami-minimal-*` | 2 GiB | SSM Agent·awscli 없음 |
| `al2023-ami-2023.*-x86_64` | 8 GiB | **원하는 것** |

`owners = ["amazon"]`은 방어선이 못 됩니다. ECS AMI 발행 계정도 소유자 별칭이 `amazon`입니다. 그래도 `owners`는 빼면 안 됩니다(커뮤니티 AMI가 들어옴).
커널까지 고정(`...-kernel-6.1-x86_64`)하면 재현성은 올라가지만 AWS가 기본 커널을 올릴 때 `no results`로 실습이 죽으므로 **8명 동시 실습에서는 커널 미고정**을 택했습니다.

### 3. `aws_key_pair`를 만들지 않는다 (= SSH 접속 없음)
| 방식 | 문제 |
|------|------|
| `aws_key_pair` + 로컬 `.pem` | 8명 × macOS/Windows/WSL 경로·`chmod 400` 문제로 시간 블랙홀 |
| `tls_private_key` | **비밀키가 tfstate에 평문 저장.** Week1에서 "state는 평문" 경고를 한 직후에 이걸 하는 건 자기모순 |
| 콘솔에서 키 생성 | IaC 수업 취지 훼손 |

SG의 22번 규칙은 **남겨둡니다**. 문법 학습 + drift 실습 교보재 + 최소 권한 습관. SSM Session Manager는 퍼블릭 서브넷이라 엔드포인트 없이도 되지만 IAM role·instance profile 3개가 늘고(`Plan: 7 to add` 체크포인트가 깨짐) 플러그인 설치가 필요해 세션 중에는 제외했습니다.

### 4. SG는 인라인 `ingress`/`egress`를 쓴다 (분리 리소스 아님)
provider 6.x 문서는 신규 코드에 `aws_vpc_security_group_ingress_rule`을 권하지만, 2주차 교육용으로는 인라인이 낫습니다.
- **`5 to add` → `2 to add`(합계 7개)** 라는 체크포인트가 유지됩니다. 규칙을 분리하면 9개가 되어 워크북·README·PR 템플릿의 숫자를 전부 고쳐야 합니다.
- **drift 실습이 인라인에서만 성립합니다.** 콘솔에서 손으로 80번 포트를 열면 인라인은 plan이 `-`로 제거를 제안하지만, 분리 리소스는 state에 없어서 **아무 일도 일어나지 않습니다.** "코드가 정답"을 가르치는 데 인라인이 압도적입니다.
- 리팩터링 자체를 뒤 주차 소재로 쓸 수 있습니다.

⚠️ 인라인과 분리 리소스를 **섞어 쓰면 서로의 규칙을 지웁니다.**

### 5. `associate_public_ip_address`를 쓰지 않는다
퍼블릭 IP는 서브넷의 `map_public_ip_on_launch` 하나로만 통제합니다. 두 곳에 진실이 갈리고, 이 속성은 **ForceNew**라서 나중에 값을 바꾸면 인스턴스가 재생성됩니다. 참고로 이 자동 할당 IP는 EIP가 아니므로 **terminate 시 반납되어 남아서 과금될 여지가 없습니다.**

### 6. `default_tags`를 2주차에 도입한다
```hcl
provider "aws" { default_tags { tags = { Project = ..., Study = ..., Week = "2", ManagedBy = "terraform" } } }
```
이번 주 주제가 "state 내부 관찰"인데, `default_tags`는 **`tags`(내가 쓴 것) vs `tags_all`(병합 결과)** 라는 대조를 공짜로 줍니다. 7개 리소스에서 같은 대조가 반복되니 설명 1회로 끝납니다.
**`Name`은 `default_tags`에 넣지 않습니다**. 모든 리소스 이름이 같아져 콘솔에서 구분이 안 됩니다.

### 7. `variables.tf`의 `validation`으로 사고를 코드에서 막는다
| 변수 | 검증 | 막는 사고 |
|------|------|----------|
| `my_ip` | `can(cidrnetmask("${var.my_ip}/32"))` | `/32` 중복 입력, `999.1.1.1`, IPv6, `CHANGE-ME` → **apply 중간(SG 생성)에 죽는 것**을 plan 이전으로 옮김 |
| `project_name` | 소문자·숫자·하이픈 3~40자 | 리소스 네이밍 오류 |
| `instance_type` | `t3.micro` / `t2.micro` 만 | **큰 타입 실수로 인한 과금** |

`cidrnetmask()`가 정규식보다 낫습니다. `^([0-9]{1,3}\.){3}[0-9]{1,3}$`는 `999.1.1.1`을 통과시킵니다.

---

## 의존성 그래프 (참조 11개 → 레벨 5단)

| 레벨 | 리소스 |
|------|--------|
| 0 | `data.aws_ami.al2023`, `data.aws_availability_zones.available` |
| 1 | `aws_vpc.main` |
| 2 | `aws_subnet.public`, `aws_internet_gateway.gw`, `aws_security_group.web` |
| 3 | `aws_route_table.public`, `aws_instance.web` |
| 4 | `aws_route_table_association.public` |

**`aws_instance.web`은 `aws_route_table_association`에 의존하지 않습니다.** 참조가 없으니까요. 오늘은 문제가 안 되지만 `user_data`로 패키지를 받으면 인터넷이 아직 없어 실패하는 경쟁 상태가 생깁니다. 실무에서 `depends_on = [aws_internet_gateway.gw]`를 쓰는 이유입니다.

destroy는 이 그래프의 역순입니다.
```
[1] instance ┃ association   [2] sg ┃ subnet ┃ route_table   [3] igw   [4] vpc
```

## 비용 (서울 리전, 실측 단가)

| 리소스 | 과금 |
|--------|------|
| VPC · subnet · IGW · route table · association · SG | **무료** |
| EC2 t3.micro | $0.0130 / 시간 |
| 퍼블릭 IPv4 (자동 할당분도 과금) | $0.005 / 시간 |
| EBS root 8GiB gp3 | $0.0912 / GB-월 ≈ $0.001 / 시간 |
| **합계** | **≈ $0.019 / 시간 (약 27원)** |

43분 실습 ≈ 20원. **destroy를 잊고 한 달 = 약 $13.9 (약 2만원).**
AMI 필터를 안 고쳐 30GiB 이미지를 쓰면 한 달 약 $15.7이 되고 프리티어 EBS 30GB를 한 대로 소진합니다.

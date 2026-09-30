## 이번 주 실습/과제 PR

- 주차: Week 2 (리소스 문법 & State)
- GitHub ID:
- 브랜치: `week2/{github-id}`
- 제출 폴더: `submissions/{github-id}/`

> 리뷰 후 머지됩니다. `practice/`는 건드리지 않았는지 확인해주세요.

### DoD 체크리스트
- [ ] `terraform init` 성공, `.terraform.lock.hcl` 커밋됨
- [ ] `apply` 두 번 성공 (`5 added` → `2 added`), `state list` 9줄
- [ ] `state show aws_instance.web`으로 `private_ip` / `public_ip` / `instance_state` 확인
- [ ] **`dependencies` 배열을 열어 의존성 지도와 대조**
- [ ] drift 실습(콘솔 태그 변경 → `plan`)까지 해봄
- [ ] **`terraform destroy` 완료 (`7 destroyed`) & `state list` 빈 출력**
- [ ] `git status`로 자격증명 / `*.tfvars` / `*.tfstate` / `state.json` / `*.pem` 커밋 안 됐는지 확인
- [ ] 제출 파일의 **퍼블릭 IP를 마스킹**했는지 확인

### 계정 잔존 점검 (C-4): 콘솔 또는 `scripts/check-leftover.sh`
- [ ] EC2 인스턴스: `terminated` 만
- [ ] EBS 볼륨(`available` 상태): 0개
- [ ] Elastic IP: 0개
- [ ] NAT Gateway: 0개
- [ ] VPC: 내 VPC 없음

### 오늘 만든 것 (요약)


### 참조 → 그래프 확인
`aws_instance.web`의 `dependencies` 배열:
```
(붙여넣기)
```
- 이 배열이 의존성 지도의 몇 번인가:
- `aws_route_table_association.public`이 이 배열에 **없는** 이유:

### `~` vs `-/+` (심화 B-6를 했다면)
- `# forces replacement` 주석이 붙은 속성:
- 그때 숫자: `___ to add, ___ to change, ___ to destroy`
- apply하지 않고 원복했는지 (`plan`이 `No changes.`):

### drift 실습 (B-5)
- `plan -refresh-only`의 맨 위 Note 한 줄:
- Terraform이 제안한 방향 (콘솔 값 유지 / 코드 값 복구):

### 막힌 지점 / 질문


### destroy 전 `terraform state list`
```
(destroy하면 확인할 수 없으므로 미리 복사해둔 출력, 9줄)
```

### destroy 후 `terraform state list`
```
(완전히 빈 출력이어야 함. 데이터 소스까지 사라집니다)
```

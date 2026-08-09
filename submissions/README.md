# submissions

Week2 실습 제출 폴더입니다. **본인 GitHub ID로 폴더를 만들어** 제출하세요.

```
submissions/
├── kdh1834/
│   ├── network.tf
│   ├── compute.tf
│   ├── outputs.tf
│   ├── variables.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── example.tfvars
│   ├── .terraform.lock.hcl
│   ├── state-list.txt        # destroy 전에 저장한 증빙 (퍼블릭 IP는 마스킹!)
│   └── observations.md       # 워크북 [관찰 ✍️] 답안
└── {your-github-id}/
    └── ...
```

## 규칙

- 폴더 이름은 **본인 GitHub ID**. 사람마다 폴더가 달라서 PR이 충돌하지 않고 전부 머지됩니다.
- **`practice/`는 건드리지 마세요.** 거기는 다음 사람이 풀 `# TODO` 스켈레톤입니다.
- **`terraform.tfvars`(내 공인 IP) · `terraform.tfstate` · `state.json`은 절대 커밋 금지.** `.gitignore`가 막고 있지만, 푸시 전에 `git status`로 한 번 더 확인하세요.
- `state-list.txt`에서 **두 가지를 반드시 지우거나 마스킹**하세요.
  - **퍼블릭 IP** (`x.x.x.x`). 22번이 열려 있던 서버 주소
  - **ARN 안의 계정번호 12자리** (`arn:aws:ec2:ap-northeast-2:123456789012:instance/...` → `<account-id>`)

## `state-list.txt`에 넣을 것 (destroy 전에 저장)

`practice/` 안에서 실행합니다. `ID`를 본인 GitHub ID로 바꾸세요.

```bash
ID=본인-github-id
mkdir -p "../submissions/$ID"

terraform state list                     >  "../submissions/$ID/state-list.txt"

# arn(계정번호)과 public_ip 는 빼고 저장
terraform state show aws_instance.web \
  | grep -Ev 'arn|public_ip|public_dns'  >> "../submissions/$ID/state-list.txt"

jq -r '.resources[] | "\(.type).\(.name)  <-  \(.instances[0].dependencies // [] | join(", "))"' \
  terraform.tfstate                      >> "../submissions/$ID/state-list.txt"
```

저장한 뒤 **파일을 한 번 눈으로 읽고** 커밋하세요.

자세한 절차는 [루트 README §5](../README.md).

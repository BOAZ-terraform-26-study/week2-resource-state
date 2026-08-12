### [관찰 ✍️] A-6 기록

- `Creating...`이 **같은 순간에** 뜬 리소스 이름 전부: `aws_internet_gateway.gw`, `aws_subnet.public` (2개. SG는 아직 안 만들어서 2개만)
- `aws_route_table.public`이 `aws_internet_gateway.gw`보다 늦게 시작한 이유를 **참조 번호로**: `⑤` (route.gateway_id로 IGW를 참조해서 IGW를 기다림)
- 가장 마지막에 `Creation complete`가 뜬 리소스: `aws_route_table_association.public` / 의존성 지도의 예측과 같은가: `같음` (4층이라 맨 마지막)
- `state list` 줄 수: `7` / 그중 실제 AWS 리소스는 몇 개: `5` (data 2개 제외)
- `subnet_az` 값: `ap-northeast-2a`

### [관찰 ✍️] B-3 기록

- `Creation complete` 순서: `aws_security_group.web` → `aws_instance.web`
- EC2 하나 만드는 데 걸린 초: `13초` / A-6의 네트워크 5개 전체는: `약 14초` (subnet 11초가 대부분)
- 의존성 지도의 **4층은 association**인데, 로그에서 **가장 늦게 끝난** 것은 무엇이었나: `aws_instance.web`
- 왜 다른가 (한 문장): `association은 시작만 늦고 1초면 끝나지만, EC2는 running 상태 대기로 완료가 가장 늦어서`
- 퍼블릭 IP가 붙었는데 EIP는 안 만들었습니다. 어느 인자 덕분인가: `subnet의 map_public_ip_on_launch = true`

### [관찰 ✍️] B-4 기록 (이 문항들이 오늘의 정체성입니다)

- `state list` 총 줄 수: `9` / 그중 `data.`로 시작하는 줄: `2`
- `state show aws_instance.web`의 `private_ip`: `10.0.1.76` / `instance_state`: `running`
- `tags`의 키 개수: `1` / `tags_all`의 키 개수: `5` / 차이가 나는 이유: `tags_all은 내 tags에 provider default_tags(ManagedBy·Project·Study·Week)를 합친 값이라`
- `aws_instance.web`의 `dependencies` 배열 전체: `["aws_security_group.web", "aws_subnet.public", "aws_vpc.main", "data.aws_ami.al2023", "data.aws_availability_zones.available"]`
- 그 배열이 의존성 지도의 **몇 번**에 해당하나: `직접 참조 ⑨·⑩·⑪, 여기에 간접 의존인 vpc·az까지 기록됨`
- 그 배열에 `aws_route_table_association.public`이 **없는** 이유: `EC2가 association을 참조하지 않아서 (순서상 뒤지만 의존은 아님)`
- `aws_vpc.main`의 `dependencies`: `null` (왜 그럴까?) `아무것도 참조 안 하는 출발점(1층)이라`
- 최상위 `serial` 값: `9` (왜 이 숫자일까?) `serial은 apply 횟수가 아니라 state 저장 횟수. 한 apply가 여러 번 저장해서 더 큼`
- `mode`가 `"data"`인 항목 수: `2`
- `terraform_version`: `1.15.8`
- **`state.json`이 `git status`에 보이는가**: `안 보임` (.gitignore로 무시)

### [관찰 ✍️] B-5 기록

- `plan -refresh-only`의 **맨 위 Note 한 줄**을 그대로: `Note: Objects have changed outside of Terraform`
- `terraform plan`의 숫자: `0 to add, 1 to change, 0 to destroy`
- Terraform이 제안한 방향 (콘솔 값 유지 / 코드 값으로 복구): `코드 값으로 복구`
- `tags`와 `tags_all`이 **둘 다** 바뀐 이유: `바꾼 Name이 tags에 있고, tags_all은 그 tags를 포함해서 양쪽에 반영됨`

### [관찰 ✍️] B-6 기록

- `instance_type` 변경은 `~`인가 `-/+`인가: `~` (in-place. 단 서버는 잠깐 멈춤)
- `# forces replacement` 주석이 붙은 속성 이름: `cidr_block` (subnet), 연쇄로 `subnet_id` (instance·association)
- 서브넷 cidr 변경 시 숫자: `3 to add, 0 to change, 3 to destroy`
- 왜 3개인가 (참조 번호로): `subnet 교체 → 참조하는 association(⑥)·instance(⑨)도 연쇄 교체`
- **apply 하지 않았음을 확인.** `terraform plan`이 `No changes.` 인가: `예` (실험 코드 원복 후 확인)

### [관찰 ✍️] C-2·C-3 기록

- 가장 먼저 `Destroying...`이 뜬 리소스: `aws_route_table_association.public`, `aws_instance.web` / 그것이 **리프 노드인 이유**: `아무도 이 둘을 참조하지 않아서`
- 가장 오래 걸린 삭제와 초: `aws_instance.web (50초, 인스턴스 종료 대기)` (igw도 48초)
- 예측(C-1)이 틀린 지점: `route_table·igw는 1초·48초에 먼저 정리됐는데 subnet·sg는 instance(50초)를 기다렸다 삭제됨. igw가 subnet·sg보다 먼저 끝나서 층 그림과 다름`
- destroy 후 `state list` 줄 수: `0` (완전히 빈 출력)
- `resources` 배열 길이: `0` / `serial`: `21` → 왜 늘었을까: `destroy도 저장 작업이라 하나씩 지울 때마다 +1`

### [관찰 ✍️] A-6 기록

- `Creating...`이 **같은 순간에** 뜬 리소스 이름 전부: `aws_internet_gateway.gw`, `aws_subnet.public`
- `aws_route_table.public`이 `aws_internet_gateway.gw`보다 늦게 시작한 이유를 **참조 번호로**: `⑤`
- 가장 마지막에 `Creation complete`가 뜬 리소스: `aws_route_table_association.public` / 의존성 지도의 예측과 같은가: `같음`
- `state list` 줄 수: `7` / 그중 실제 AWS 리소스는 몇 개: `5`
- `subnet_az` 값: `ap-northeast-2a`

### [관찰 ✍️] B-3 기록

- `Creation complete` 순서: `aws_security_group.web` → `aws_instance.web`
- EC2 하나 만드는 데 걸린 초: `13초` / A-6의 네트워크 5개 전체는: `약 14초`
- 의존성 지도의 **4층은 association**인데, 로그에서 **가장 늦게 끝난** 것: `aws_instance.web`
- 왜 다른가: `층은 시작 순서만 정하고, 완료 시간은 실제 작업량이 정하기 때문`
- 퍼블릭 IP가 붙었는데 EIP는 안 만들었습니다. 어느 인자 덕분인가: `aws_subnet.public의 map_public_ip_on_launch = true`

### [관찰 ✍️] B-4 기록

- `state list` 총 줄 수: `9` / 그중 `data.`로 시작하는 줄: `2`
- `private_ip`: `10.0.1.4` / `instance_state`: `running`
- `tags` 키 개수: `1` / `tags_all` 키 개수: `5` / 차이 이유: `default_tags가 자동으로 합쳐짐`
- `aws_instance.web`의 `dependencies` 배열 전체: `aws_security_group.web, aws_subnet.public, aws_vpc.main, data.aws_ami.al2023, data.aws_availability_zones.available`
- 그 배열이 의존성 지도의 몇 번에 해당하나: `⑨ ⑩ ⑪ (직접), vpc는 간접`
- `aws_route_table_association.public`이 없는 이유: `EC2 코드가 참조하지 않아서`
- `aws_vpc.main`의 `dependencies`: `빈 배열` (아무것도 참조 안 하는 리소스라서)
- 최상위 `serial` 값: `9` (apply 횟수가 아니라 state 저장 횟수라서)
- `mode`가 `"data"`인 항목 수: `2`
- `terraform_version`: `1.15.8`
- `state.json`이 `git status`에 보이는가: `아니오`

### [관찰 ✍️] C-2·C-3 기록

- 가장 먼저 `Destroying...`이 뜬 리소스: `aws_route_table_association.public`, `aws_instance.web` / 리프 노드인 이유: `아무도 참조하지 않아서`
- 가장 오래 걸린 삭제와 초: `aws_instance.web, 60초`
- 예측(C-1)이 틀린 지점: `subnet·security_group은 route_table과 같은 층인데, 실제로는 instance가 완전히 terminate될 때까지 기다린 뒤에야 삭제됨`
- destroy 후 `state list` 줄 수: `0`
- `resources` 배열 길이: `0` / `serial`: `19` → 왜 늘었을까: `destroy도 저장 작업이라서`

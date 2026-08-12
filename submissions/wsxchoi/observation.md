### [관찰 ✍️] A-6 기록

> compute.tf 까지 채우고 apply를 한 결과

- `Creating...`이 **같은 순간에** 뜬 리소스 이름 전부: `___`
- `aws_route_table.public`이 `aws_internet_gateway.gw`보다 늦게 시작한 이유를 **참조 번호로**: `route table은 4단계, igw는 2단계, 따라서 igw가 먼저 생김.`

```
[4단계]  aws_instance.web ┃ aws_route_table_association.public
[3단계]  aws_security_group.web ┃ aws_route_table.public
[2단계]  aws_internet_gateway.gw ┃ aws_subnet.public
[1단계]  aws_vpc.main
```

- 가장 마지막에 `Creation complete`가 뜬 리소스: `aws_instance.web` / 의존성 지도의 예측과 같은가: `같다`
- `state list` 줄 수: `9` / 그중 실제 AWS 리소스는 몇 개: `7`
    - 실제 리소스 7개 + data 소스 2개
    - `data.aws_ami.al2023`
    - `data.aws_availability_zones.available`

- `subnet_az` 값: `subnet_az = "ap-northeast-2a"`

```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s

aws_internet_gateway.gw: Creating...
aws_subnet.public: Creating...
aws_security_group.web: Creating...

aws_internet_gateway.gw: Creation complete after 0s 

aws_route_table.public: Creating...
aws_route_table.public: Creation complete after 1s 

aws_security_group.web: Creation complete after 2s 

aws_subnet.public: Still creating... [00m10s elapsed]
aws_subnet.public: Creation complete after 11s 

aws_route_table_association.public: Creating...
aws_instance.web: Creating...

aws_route_table_association.public: Creation complete after 0s 

aws_instance.web: Still creating... [00m10s elapsed]
aws_instance.web: Creation complete after 13s
```

### [관찰 ✍️] B-3 기록

- `Creation complete` 순서: `___` → `___`
- EC2 하나 만드는 데 걸린 초: `13초` / A-6의 네트워크 5개 전체는: `___`
- 의존성 지도의 **4층은 association**인데, 로그에서 **가장 늦게 끝난** 것은 무엇이었나: `aws_instance.web`
- 왜 다른가 (한 문장): `___`
- 퍼블릭 IP가 붙었는데 EIP는 안 만들었습니다. 어느 인자 덕분인가: `map_public_ip_on_launch = true`

### [관찰 ✍️] C-2·C-3 기록

- 가장 먼저 `Destroying...`이 뜬 리소스: `aws_route_table_association.public` / 그것이 **리프 노드인 이유**: `___`
- 가장 오래 걸린 삭제와 초: `EC2, 1m1s`
- 예측(C-1)이 틀린 지점: `___`
- destroy 후 `state list` 줄 수: `0`
- `resources` 배열 길이: `0` / `serial`: `18` → 왜 늘었을까: `___`

```
aws_route_table_association.public: Destroying...

aws_instance.web: Destroying...

aws_route_table_association.public: Destruction complete after 1s

aws_route_table.public: Destroying...
aws_route_table.public: Destruction complete after 0s

aws_internet_gateway.gw: Destroying... 
aws_instance.web: Still destroying... 
aws_internet_gateway.gw: Still destroying... 
aws_instance.web: Still destroying... 
aws_internet_gateway.gw: Still destroying... 
aws_instance.web: Still destroying...
aws_internet_gateway.gw: Still destroying... 
aws_instance.web: Still destroying... 
aws_internet_gateway.gw: Still destroying... 

aws_internet_gateway.gw: Destruction complete after 48s

aws_instance.web: Still destroying... 
aws_instance.web: Still destroying... 

aws_instance.web: Destruction complete after 1m1s

aws_subnet.public: Destroying...
aws_security_group.web: Destroying... 

aws_subnet.public: Destruction complete after 0s

aws_security_group.web: Destruction complete after 0s

aws_vpc.main: Destroying... 
aws_vpc.main: Destruction complete after 1s
```
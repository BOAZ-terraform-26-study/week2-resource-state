# ---------------------------------------------------------------------------
# network.tf: VPC / subnet / IGW / route table / association  (리소스 5개)
# 참조 ① ② ③ ④ ⑤ ⑥ ⑦ 이 이 파일에서 만들어진다.
# ---------------------------------------------------------------------------

# 이 계정에서 실제로 쓸 수 있는 AZ 목록을 AWS에 물어본다.
# AZ 이름("ap-northeast-2a")은 계정마다 물리 AZ에 다르게 매핑되고,
# 오래된 계정은 특정 AZ에 서브넷을 못 만들 수도 있다. 그래서 하드코딩하지 않는다.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id # 참조 ①
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0] # 참조 ②

  # 이 서브넷에서 뜨는 인스턴스는 퍼블릭 IPv4를 자동으로 받는다.
  # EIP를 만들지 않아도 인터넷에서 도달 가능한 주소가 붙는 이유가 이 한 줄이다.
  # 주의: 퍼블릭 IPv4 자체가 시간당 $0.005 과금된다(2024-02-01부터).
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id # 참조 ③

  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # 참조 ④

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id # 참조 ⑤. IGW를 먼저 만들게 하는 참조
  }

  tags = { Name = "${var.project_name}-rt-public" }
}

# 라우트 테이블을 서브넷에 실제로 붙인다.
# "연결" 자체가 하나의 리소스다. 이게 없으면 IGW가 있어도 밖으로 나갈 수 없다.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id      # 참조 ⑥
  route_table_id = aws_route_table.public.id # 참조 ⑦
}

# ---------------------------------------------------------------------------
# 여기에 NAT Gateway / Elastic IP 를 추가하지 마세요.
#   NAT Gateway : 시간당 과금 + 데이터 처리 과금 (프리티어 없음)
#   EIP         : 유휴 상태에서도 시간당 과금
# 이번 주 실습은 퍼블릭 서브넷 하나로 충분합니다.
# ---------------------------------------------------------------------------

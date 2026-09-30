# ---------------------------------------------------------------------------
# network.tf: 리소스 5개(vpc / subnet / igw / route table / association)
# 참조 ① ~ ⑦ 을 여기서 작성합니다.  자세한 설명은 실습워크북 A-3 · A-4
# ---------------------------------------------------------------------------

# [주어짐] 이 계정에서 쓸 수 있는 AZ를 AWS에서 조회하는 데이터 소스.
#   AZ 이름("ap-northeast-2a")은 계정마다 물리 AZ에 다르게 매핑되므로 하드코딩하지 않습니다.
data "aws_availability_zones" "available" {
  state = "available"
}

# [주어짐] 레벨 1. 아무것도 참조하지 않는 유일한 리소스.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# TODO(L1): 퍼블릭 서브넷.  (워크북 A-3 · 참조 ① ②)
#   - 타입/이름: resource "aws_subnet" "public"
#   - vpc_id                  = aws_vpc.main.id                                <- 참조 ①
#   - cidr_block              = "10.0.1.0/24"
#   - availability_zone       = data.aws_availability_zones.available.names[0]  <- 참조 ②
#   - map_public_ip_on_launch = true    (EIP 없이 퍼블릭 IP를 받게 하는 한 줄)
#   - tags                    = { Name = "${var.project_name}-public" }


# TODO(L1): 인터넷 게이트웨이.  (워크북 A-4 · 참조 ③)
#   - 타입/이름: resource "aws_internet_gateway" "gw"
#   - vpc_id = aws_vpc.main.id
#   - tags   = { Name = "${var.project_name}-igw" }


# TODO(L1): 라우트 테이블 + 0.0.0.0/0 -> IGW.  (워크북 A-4 · 참조 ④ ⑤)
#   - 타입/이름: resource "aws_route_table" "public"
#   - vpc_id = aws_vpc.main.id
#   - route 인라인 블록 하나:
#       cidr_block = "0.0.0.0/0"
#       gateway_id = aws_internet_gateway.gw.id     <- 이 참조가 IGW를 먼저 만들게 한다
#   - tags = { Name = "${var.project_name}-rt-public" }


# TODO(L1): 라우트 테이블을 서브넷에 붙이는 연결.  (워크북 A-4 · 참조 ⑥ ⑦)
#   "연결" 자체가 리소스입니다. 인자가 참조 두 개뿐인 리소스라서 그래프의 마지막 레벨이 됩니다.
#   - 타입/이름: resource "aws_route_table_association" "public"
#   - subnet_id      = aws_subnet.public.id
#   - route_table_id = aws_route_table.public.id


# ---------------------------------------------------------------------------
# 여기에 NAT Gateway / Elastic IP 를 추가하지 마세요 (시간당 과금, 프리티어 없음).
# 퍼블릭 서브넷 하나로 오늘 실습은 충분합니다.
# ---------------------------------------------------------------------------

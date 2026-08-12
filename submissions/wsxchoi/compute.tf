# ---------------------------------------------------------------------------
# compute.tf: 리소스 2개(security group / EC2)
# 참조 ⑧ ~ ⑪ 을 여기서 긋습니다.  자세한 설명은 실습워크북 B-1
# ---------------------------------------------------------------------------

# [주어짐] 최신 Amazon Linux 2023 AMI. AMI ID 하드코딩 금지.
#
#   이름 패턴이 'al2023-ami-2023.*' 로 시작까지 고정된 이유가 있습니다.
#   'al2023-ami-*-x86_64' 처럼 느슨하게 두면 아래 것들이 후보에 섞이고
#   most_recent = true 가 엉뚱한 걸 고릅니다.
#     - al2023-ami-ecs-neuron-hvm-* : ECS 전용, 루트 볼륨 30GiB (EBS 비용 3.75배)
#     - al2023-ami-minimal-*        : SSM Agent 등이 빠진 최소 이미지
#   owners = ["amazon"] 은 방어선이 못 됩니다 (ECS AMI 발행 계정도 별칭이 amazon).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"] # instance_type(t3.micro)과 반드시 일치
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# TODO(L1): 보안 그룹.  (워크북 B-1 · 참조 ⑧)
#   - 타입/이름: resource "aws_security_group" "web"
#   - name        = "${var.project_name}-web-sg"
#   - description = "boaz w2 lab: SSH from my IP only"
#   - vpc_id      = aws_vpc.main.id     <- 이걸 빼면 기본 VPC에 만들어져 EC2 생성이 실패한다
#   - ingress 블록: description/from_port 22/to_port 22/protocol "tcp"
#                   cidr_blocks = ["${var.my_ip}/32"]      <- 0.0.0.0/0 금지
#   - egress  블록: from_port 0/to_port 0/protocol "-1"/cidr_blocks = ["0.0.0.0/0"]
#   - tags = { Name = "${var.project_name}-web-sg" }


resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "boaz w2 lab: SSH from my IP only"
  vpc_id      = aws_vpc.main.id # 참조 ⑧

  ingress { # 들어오는 것
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] # 내 IP 하나만
  }

  egress { # 나가는 것
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 = 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"] # 어디로든 나갈 수 있음
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

# TODO(L1): EC2 인스턴스.  (워크북 B-1 · 참조 ⑨ ⑩ ⑪)
#   - 타입/이름: resource "aws_instance" "web"
#   - ami                    = data.aws_ami.al2023.id       <- 오늘 유일한 data. 참조 (⑪)
#   - instance_type          = var.instance_type
#   - subnet_id              = aws_subnet.public.id         <- ⑨
#   - vpc_security_group_ids = [aws_security_group.web.id]  <- ⑩ 대괄호! (SG는 여러 개 가능)
#   - root_block_device 블록: volume_type "gp3" / volume_size 8 / delete_on_termination true
#   - metadata_options 블록:  http_tokens = "required"   (IMDSv2 강제)
#   - tags = { Name = "${var.project_name}-web" }
#
#   associate_public_ip_address 는 쓰지 마세요. 퍼블릭 IP는 서브넷의
#   map_public_ip_on_launch 하나로만 통제합니다 (진실이 두 곳으로 갈리는 것 방지).

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id # 참조 ⑪
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id        # 참조 ⑨
  vpc_security_group_ids = [aws_security_group.web.id] # 참조 ⑩

  root_block_device { # 서버의 디스크
    volume_type           = "gp3"
    volume_size           = 8    # 8 GiB
    delete_on_termination = true # 서버 지울 때 디스크도 같이 삭제
  }

  metadata_options {
    http_tokens = "required" # 보안 설정. 오늘은 몰라도 됩니다 (아래 NOTE)
  }

  tags = { Name = "${var.project_name}-web" }
}

# ---------------------------------------------------------------------------
# 키페어(aws_key_pair)를 만들지 마세요 = 오늘은 SSH 접속을 하지 않습니다.
# 비밀키는 tfstate에 평문으로 남고 .pem 파일은 커밋 사고가 됩니다.
# 오늘의 성공 기준은 접속이 아니라 instance_state = running + 퍼블릭 IP 할당입니다.
# ---------------------------------------------------------------------------

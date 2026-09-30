# ---------------------------------------------------------------------------
# compute.tf: AMI 데이터 소스 / security group / EC2  (리소스 2개)
# 참조 ⑧ ⑨ ⑩ ⑪ 이 이 파일에서 만들어진다.
# ---------------------------------------------------------------------------

# 최신 Amazon Linux 2023 AMI. AMI ID는 리전마다 다르고 몇 주마다 갱신되므로
# 절대 하드코딩하지 않는다.
#
# 이름 패턴을 'al2023-ami-2023.*' 로 **시작까지 고정**하는 이유:
#   'al2023-ami-*-x86_64' 처럼 느슨하게 두면 아래 것들까지 후보에 들어오고
#   most_recent = true 가 그중 가장 최근 것을 선택한다.
#     - al2023-ami-ecs-neuron-hvm-* : ECS 전용, 루트 볼륨 30GiB (EBS 비용 3.75배)
#     - al2023-ami-ecs-hvm-*        : ECS 전용
#     - al2023-ami-minimal-*        : SSM Agent·awscli 등이 빠진 최소 이미지(2GiB)
#   owners = ["amazon"] 은 이걸 막아주지 못한다. ECS AMI를 발행하는 AWS 서비스팀
#   계정도 소유자 별칭이 "amazon" 이기 때문이다.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"] # instance_type(t3.micro)과 반드시 일치해야 한다
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

# 주의: 아래 인라인 ingress/egress 블록과, 별도 리소스인
#      aws_vpc_security_group_ingress_rule 을 절대 섞어 쓰지 말 것. 서로의 규칙을 지운다.
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "boaz w2 lab: SSH from my IP only"
  vpc_id      = aws_vpc.main.id # 참조 ⑧. 빼먹으면 기본 VPC에 만들어져 EC2 생성이 실패한다

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] # 0.0.0.0/0 으로 열지 말 것
  }

  egress {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id # 참조 ⑪ (오늘 유일한 data. 참조)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id        # 참조 ⑨
  vpc_security_group_ids = [aws_security_group.web.id] # 참조 ⑩ (리스트다)

  # 퍼블릭 IP는 서브넷의 map_public_ip_on_launch 하나로만 통제한다.
  # 여기에 associate_public_ip_address 를 또 쓰면 설정이 두 곳에 나뉘고,
  # 나중에 그 값을 바꾸면 인스턴스가 통째로 재생성(-/+)된다.

  # 루트 볼륨을 명시해 비용을 눈으로 확인한다. 8GiB gp3 ≈ $0.73/월.
  # delete_on_termination = true 라서 destroy 후 볼륨이 남지 않는다.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  # IMDSv2 강제. AL2023 기본값이지만 코드에 의도를 남긴다.
  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.project_name}-web" }
}

# ---------------------------------------------------------------------------
# 키페어(aws_key_pair)를 만들지 않습니다 = 오늘은 SSH로 접속하지 않습니다.
#   - tls_private_key 로 키를 만들면 비밀키가 tfstate에 평문으로 저장된다
#   - .pem 파일이 실습 폴더에 남아 PR로 커밋되는 사고가 발생한다
# 오늘의 성공 기준은 "접속"이 아니라 instance_state = running + 퍼블릭 IP 할당입니다.
# ---------------------------------------------------------------------------

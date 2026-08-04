#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-leftover.sh — destroy 후 계정에 과금되는 리소스가 남았는지 확인한다.
#
#   "terraform state list 가 비었다" ≠ "계정이 비었다"
#   콘솔 클릭 5번 대신 이 스크립트 한 번으로 확인하세요. (실습워크북 C-4)
#
# 사용법:
#   ./scripts/check-leftover.sh                 # 서울 리전
#   REGION=us-east-1 ./scripts/check-leftover.sh
# ---------------------------------------------------------------------------
set -uo pipefail

R="${REGION:-ap-northeast-2}"
# 이 스터디가 만든 리소스만 골라 본다 (providers.tf 의 default_tags 와 같은 값).
# 다른 프로젝트 리소스나 기본 VPC를 "남았다"고 오탐하지 않기 위함.
STUDY_TAG="${STUDY_TAG:-boaz-terraform-26}"
TAGF="Name=tag:Study,Values=$STUDY_TAG"
FOUND=0

hr() { printf '%s\n' "----------------------------------------------------------"; }

echo "리전: $R"
echo "필터: tag:Study = $STUDY_TAG  (다르게 쓰려면 STUDY_TAG=... 로 실행)"
echo "계정: $(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo '자격증명 실패')"
hr

check() {
  local label="$1" count="$2" detail="$3"
  if [ "$count" = "0" ] || [ -z "$count" ] || [ "$count" = "None" ]; then
    printf '  OK    %-28s 0\n' "$label"
  else
    printf '  남음  %-28s %s\n' "$label" "$count"
    [ -n "$detail" ] && printf '%s\n' "$detail"
    FOUND=1
  fi
}

# 1) 살아있는 EC2 인스턴스 (terminated 는 제외 — 이미 죽은 것)
#    태그로 좁히지 않는다: 실습 중 콘솔에서 손으로 띄운 인스턴스도 잡아야 하기 때문.
LIVE=$(aws ec2 describe-instances --region "$R" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'length(Reservations[].Instances[])' --output text 2>/dev/null)
LIVE_D=$(aws ec2 describe-instances --region "$R" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output text 2>/dev/null)
check "EC2 인스턴스 (과금!)" "$LIVE" "$LIVE_D"

# 2) 붙은 데 없는 EBS 볼륨 — GB-월로 계속 과금된다
VOL=$(aws ec2 describe-volumes --region "$R" --filters Name=status,Values=available \
  --query 'length(Volumes)' --output text 2>/dev/null)
VOL_D=$(aws ec2 describe-volumes --region "$R" --filters Name=status,Values=available \
  --query 'Volumes[].[VolumeId,Size,VolumeType,CreateTime]' --output text 2>/dev/null)
check "미사용 EBS 볼륨 (과금!)" "$VOL" "$VOL_D"

# 3) Elastic IP — 유휴 상태에서도 시간당 과금
EIP=$(aws ec2 describe-addresses --region "$R" --query 'length(Addresses)' --output text 2>/dev/null)
EIP_D=$(aws ec2 describe-addresses --region "$R" \
  --query 'Addresses[].[PublicIp,AllocationId,AssociationId]' --output text 2>/dev/null)
check "Elastic IP (과금!)" "$EIP" "$EIP_D"

# 4) NAT Gateway — 이번 실습에서는 아예 만들지 않아야 한다
NAT=$(aws ec2 describe-nat-gateways --region "$R" \
  --filter Name=state,Values=pending,available,deleting \
  --query 'length(NatGateways)' --output text 2>/dev/null)
NAT_D=$(aws ec2 describe-nat-gateways --region "$R" \
  --filter Name=state,Values=pending,available,deleting \
  --query 'NatGateways[].[NatGatewayId,State,VpcId]' --output text 2>/dev/null)
check "NAT Gateway (과금!)" "$NAT" "$NAT_D"

# 5) 이 스터디가 만든 VPC — 무료지만 리전당 5개 제한이라 다음 주 VpcLimitExceeded 예방
VPC=$(aws ec2 describe-vpcs --region "$R" --filters "$TAGF" \
  --query 'length(Vpcs)' --output text 2>/dev/null)
VPC_D=$(aws ec2 describe-vpcs --region "$R" --filters "$TAGF" \
  --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output text 2>/dev/null)
check "스터디 VPC (무료·개수제한)" "$VPC" "$VPC_D"

# 6) 이 스터디 서브넷에 남은 ENI (subnet/SG 삭제를 막는 범인)
SUBNETS=$(aws ec2 describe-subnets --region "$R" --filters "$TAGF" \
  --query 'Subnets[].SubnetId' --output text 2>/dev/null)
if [ -n "${SUBNETS// /}" ]; then
  ENI=$(aws ec2 describe-network-interfaces --region "$R" \
    --filters "Name=subnet-id,Values=$(echo "$SUBNETS" | tr '\t' ',')" \
    --query 'length(NetworkInterfaces)' --output text 2>/dev/null)
  check "스터디 서브넷의 ENI" "$ENI" ""
else
  printf '  OK    %-28s 0 (스터디 서브넷 자체가 없음)\n' "스터디 서브넷의 ENI"
fi

hr
if [ "$FOUND" = "0" ]; then
  echo "  전부 0 — 정리 완료. 오늘 실습 끝!"
else
  echo "  남은 것이 있습니다. terraform destroy 를 다시 실행하거나 콘솔에서 확인하세요."
  echo "  EBS/EIP/NAT 검사는 계정 전체를 보므로, 다른 프로젝트 것이 잡혔을 수도 있습니다."
  echo "  출력된 ID의 Name 태그로 내 것인지 확인하세요."
fi

# 리전 착각 대비 스윕
hr
echo "다른 리전에 실수로 만든 것이 없는지:"
for r in ap-northeast-2 us-east-1 ap-northeast-1; do
  n=$(aws ec2 describe-instances --region "$r" \
    --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'length(Reservations[].Instances[])' --output text 2>/dev/null)
  printf '  %-18s 살아있는 인스턴스 %s\n' "$r" "${n:-?}"
done

# 복사해서 terraform.tfvars 로 저장하고 값을 채우세요 (terraform.tfvars는 커밋 금지).
region       = "ap-northeast-2"
project_name = "boaz26-w2-your-github-id" # 본인 GitHub ID. 소문자·숫자·하이픈만, 3~40자

# curl -4 ifconfig.me 결과를 그대로 넣으세요. /32 를 붙이지 마세요 (코드가 붙입니다).
# CHANGE-ME 그대로 두면 plan이 실패합니다 — 일부러 그렇게 만들어 뒀습니다.
my_ip = "CHANGE-ME"

instance_type = "t3.micro" # t3.micro / t2.micro 만 허용 (과금 방지)

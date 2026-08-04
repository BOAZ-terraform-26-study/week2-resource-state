# 자격증명은 여기 넣지 않습니다. aws configure / 환경변수로만 주입.
provider "aws" {
  region = var.region

  # 이 provider가 만드는 모든 리소스에 자동으로 붙는 태그.
  # Name은 리소스마다 달라야 하므로 여기 넣지 않습니다(콘솔에서 구분이 안 됨).
  # state에서 tags(내가 쓴 것) vs tags_all(병합 결과)을 비교해 보세요. (워크북 B-4)
  default_tags {
    tags = {
      Project   = var.project_name
      Study     = "boaz-terraform-26"
      Week      = "2"
      ManagedBy = "terraform"
    }
  }
}

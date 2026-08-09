variable "region" {
  description = "리소스를 만들 리전 (스터디 공통: 서울)"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "리소스 이름 접두어. boaz26-w2-{본인-github-id} 형식"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,39}$", var.project_name))
    error_message = "project_name은 소문자·숫자·하이픈만, 3~40자여야 합니다."
  }
}

variable "my_ip" {
  description = "SSH를 허용할 본인 공인 IP. `curl -4 ifconfig.me` 결과. CIDR 아님, 순수 IP."
  type        = string

  # 코드에서 "${var.my_ip}/32" 로 조립하므로, 여기에 이미 /32 가 붙어 있으면
  # "1.2.3.4/32/32" 가 되어 아래 cidrnetmask() 가 실패합니다.
  # 정규식보다 cidrnetmask() 가 낫습니다. "999.1.1.1" 같은 값까지 걸러냅니다.
  validation {
    condition     = can(cidrnetmask("${var.my_ip}/32"))
    error_message = "my_ip는 1.2.3.4 처럼 순수 IPv4여야 합니다. /32나 CIDR을 넣지 마세요. (curl -4 ifconfig.me)"
  }
}

variable "instance_type" {
  description = "EC2 인스턴스 타입. 서울 리전 프리티어 대상은 t3.micro(x86_64)."
  type        = string
  default     = "t3.micro"

  # 실수로 큰 타입을 넣어 과금되는 것을 코드 단계에서 막습니다.
  validation {
    condition     = contains(["t3.micro", "t2.micro"], var.instance_type)
    error_message = "이번 실습은 t3.micro 또는 t2.micro 만 허용합니다 (과금 방지). t2.micro는 서울 2b/2d AZ에 없으니 t3.micro를 권장합니다."
  }
}

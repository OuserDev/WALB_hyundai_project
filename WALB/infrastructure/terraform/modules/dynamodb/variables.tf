# infrastructure/terraform/modules/dynamodb/variables.tf
# DynamoDB 모듈 변수 정의

# 필수 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod, walb)"
  type        = string
  default     = "walb"
  validation {
    condition     = contains(["dev", "staging", "prod", "walb"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}


# 테이블 기본 설정
variable "table_name" {
  description = "DynamoDB 테이블 이름 (null일 경우 자동 생성)"
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "DynamoDB 과금 모드"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "과금 모드는 PROVISIONED 또는 PAY_PER_REQUEST여야 합니다."
  }
}

variable "read_capacity" {
  description = "읽기 용량 단위 (PROVISIONED 모드에서만 사용)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "쓰기 용량 단위 (PROVISIONED 모드에서만 사용)"
  type        = number
  default     = 5
}

# 키 설정
variable "hash_key" {
  description = "해시 키 (파티션 키)"
  type        = string
}

variable "range_key" {
  description = "범위 키 (정렬 키, 선택사항)"
  type        = string
  default     = null
}

# 속성 정의
variable "attributes" {
  description = "DynamoDB 테이블 속성 목록"
  type = list(object({
    name = string
    type = string
  }))
  validation {
    condition = alltrue([
      for attr in var.attributes :
      contains(["S", "N", "B"], attr.type)
    ])
    error_message = "속성 타입은 S(String), N(Number), B(Binary) 중 하나여야 합니다."
  }
}

# 로컬 보조 인덱스
variable "local_secondary_indexes" {
  description = "로컬 보조 인덱스 목록"
  type = list(object({
    name               = string
    range_key          = string
    projection_type    = string
    non_key_attributes = list(string)
  }))
  default = []
}

# 글로벌 보조 인덱스
variable "global_secondary_indexes" {
  description = "글로벌 보조 인덱스 목록"
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    write_capacity     = number
    read_capacity      = number
    projection_type    = string
    non_key_attributes = list(string)
  }))
  default = []
}

# TTL 설정
variable "ttl_enabled" {
  description = "TTL(Time To Live) 활성화"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "TTL 속성 이름"
  type        = string
  default     = "ttl"
}

# 암호화 설정 (ISMS-P 컴플라이언스)
variable "create_kms_key" {
  description = "DynamoDB 암호화용 KMS 키 생성 여부"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "기존 KMS 키 ARN (create_kms_key가 false일 때 사용)"
  type        = string
  default     = null
}

variable "kms_deletion_window" {
  description = "KMS 키 삭제 대기 기간 (일)"
  type        = number
  default     = 7
}

# Point-in-time Recovery (ISMS-P 컴플라이언스)
variable "point_in_time_recovery_enabled" {
  description = "Point-in-time Recovery 활성화"
  type        = bool
  default     = true
}

# DynamoDB Streams
variable "stream_enabled" {
  description = "DynamoDB Streams 활성화"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream 뷰 타입"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
  validation {
    condition = contains([
      "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"
    ], var.stream_view_type)
    error_message = "유효한 Stream 뷰 타입을 입력해주세요."
  }
}

# 삭제 보호
variable "deletion_protection_enabled" {
  description = "삭제 보호 비활성화"
  type        = bool
  default     = false
}

# Auto Scaling 설정
variable "enable_autoscaling" {
  description = "Auto Scaling 활성화 (PROVISIONED 모드에서만)"
  type        = bool
  default     = true
}

variable "autoscaling_read_min_capacity" {
  description = "읽기 Auto Scaling 최소 용량"
  type        = number
  default     = 1
}

variable "autoscaling_read_max_capacity" {
  description = "읽기 Auto Scaling 최대 용량"
  type        = number
  default     = 100
}

variable "autoscaling_write_min_capacity" {
  description = "쓰기 Auto Scaling 최소 용량"
  type        = number
  default     = 1
}

variable "autoscaling_write_max_capacity" {
  description = "쓰기 Auto Scaling 최대 용량"
  type        = number
  default     = 100
}

variable "autoscaling_read_target_value" {
  description = "읽기 Auto Scaling 목표 값 (%)"
  type        = number
  default     = 70.0
}

variable "autoscaling_write_target_value" {
  description = "쓰기 Auto Scaling 목표 값 (%)"
  type        = number
  default     = 70.0
}

# GSI Auto Scaling
variable "gsi_autoscaling_read_min_capacity" {
  description = "GSI 읽기 Auto Scaling 최소 용량"
  type        = number
  default     = 1
}

variable "gsi_autoscaling_read_max_capacity" {
  description = "GSI 읽기 Auto Scaling 최대 용량"
  type        = number
  default     = 100
}

variable "gsi_autoscaling_write_min_capacity" {
  description = "GSI 쓰기 Auto Scaling 최소 용량"
  type        = number
  default     = 1
}

variable "gsi_autoscaling_write_max_capacity" {
  description = "GSI 쓰기 Auto Scaling 최대 용량"
  type        = number
  default     = 100
}

# CloudWatch 알람
variable "enable_cloudwatch_alarms" {
  description = "CloudWatch 알람 활성화"
  type        = bool
  default     = true
}

variable "read_throttle_alarm_threshold" {
  description = "읽기 스로틀 알람 임계값"
  type        = number
  default     = 0
}

variable "write_throttle_alarm_threshold" {
  description = "쓰기 스로틀 알람 임계값"
  type        = number
  default     = 0
}

variable "sns_topic_arn" {
  description = "알람 전송용 SNS 토픽 ARN"
  type        = string
  default     = null
}

# 백업 설정
variable "create_backup" {
  description = "백업 생성 여부"
  type        = bool
  default     = false
}

# Global Tables
variable "enable_global_tables" {
  description = "Global Tables 활성화"
  type        = bool
  default     = false
}

variable "global_table_regions" {
  description = "Global Tables 리전 목록"
  type        = list(string)
  default     = []
}

# Contributor Insights
variable "enable_contributor_insights" {
  description = "Contributor Insights 활성화"
  type        = bool
  default     = false
}

# 복제 설정
variable "create_replica" {
  description = "테이블 복제본 생성 여부"
  type        = bool
  default     = false
}

variable "replica_kms_key_arn" {
  description = "복제본 KMS 키 ARN"
  type        = string
  default     = null
}

variable "replica_point_in_time_recovery" {
  description = "복제본 Point-in-time Recovery"
  type        = bool
  default     = true
}

variable "replica_table_class" {
  description = "복제본 테이블 클래스"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.replica_table_class)
    error_message = "replica_table_class는 STANDARD 또는 STANDARD_INFREQUENT_ACCESS여야 합니다."
  }
}

# IAM 역할 설정
variable "create_access_role" {
  description = "DynamoDB 접근용 IAM 역할 생성 여부"
  type        = bool
  default     = false
}

variable "access_role_principals" {
  description = "IAM 역할을 가정할 수 있는 서비스 목록"
  type        = list(string)
  default     = ["ecs-tasks.amazonaws.com"]
}

variable "access_role_permissions" {
  description = "IAM 역할에 부여할 DynamoDB 권한 목록"
  type        = list(string)
  default = [
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:UpdateItem",
    "dynamodb:DeleteItem",
    "dynamodb:Query",
    "dynamodb:Scan"
  ]
}

# 테이블 클래스
variable "table_class" {
  description = "DynamoDB 테이블 클래스"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class는 STANDARD 또는 STANDARD_INFREQUENT_ACCESS여야 합니다."
  }
}

# 데이터 분류
variable "data_classification" {
  description = "데이터 분류 (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "유효한 데이터 분류: public, internal, confidential, restricted"
  }
}

# 컴플라이언스 요구사항
variable "compliance_requirements" {
  description = "컴플라이언스 요구사항 목록"
  type        = list(string)
  default     = ["ISMS-P", "ISO27001"]
}

# 성능 모드
variable "provisioned_throughput_mode" {
  description = "프로비저닝된 처리량 모드"
  type        = string
  default     = "PROVISIONED"
  validation {
    condition     = contains(["PROVISIONED", "ON_DEMAND"], var.provisioned_throughput_mode)
    error_message = "처리량 모드는 PROVISIONED 또는 ON_DEMAND여야 합니다."
  }
}

# 내보내기 설정
variable "enable_export_to_s3" {
  description = "S3로 데이터 내보내기 활성화"
  type        = bool
  default     = false
}

variable "export_s3_bucket" {
  description = "내보내기 대상 S3 버킷"
  type        = string
  default     = null
}

variable "export_s3_prefix" {
  description = "S3 내보내기 접두사"
  type        = string
  default     = "dynamodb-exports/"
}

# 가져오기 설정
variable "enable_import_from_s3" {
  description = "S3에서 데이터 가져오기 활성화"
  type        = bool
  default     = false
}

variable "import_s3_bucket_source" {
  description = "가져오기 소스 S3 버킷"
  type        = string
  default     = null
}

# 태그
variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "security-monitoring"
    Environment = "walb"
  }
}
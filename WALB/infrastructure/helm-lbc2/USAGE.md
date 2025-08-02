# AWS Load Balancer Controller Helm 배포 자동화 (App2 전용)

이 디렉토리는 App2 전용 AWS Load Balancer Controller를 Helm Chart로 배포하기 위한 Terraform 구성을 포함합니다.

## 📋 사전 요구사항

1. **Terraform2 인프라 배포 완료**: `../terraform2` 디렉토리에서 `terraform apply` 완료
2. **필요한 도구 설치**:
   - Terraform >= 1.0
   - jq (JSON 파싱용)
   - AWS CLI (인증 설정 완료)

## 🚀 빠른 시작

### 1단계: terraform.tfvars 자동 생성

```bash
# 스크립트 실행 권한 확인
chmod +x generate-tfvars.sh

# terraform.tfvars 파일 자동 생성
./generate-tfvars.sh
```

### 2단계: Terraform 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# AWS Load Balancer Controller 배포 (App2 전용)
terraform apply
```

## 📄 generate-tfvars.sh 스크립트 기능

이 스크립트는 다음과 같은 작업을 자동으로 수행합니다:

1. **인프라 정보 수집**: `../terraform2` 디렉토리에서 terraform output을 통해 필요한 값들을 자동 수집
2. **값 검증**: 필수 값들(클러스터 이름, VPC ID 등)이 올바르게 수집되었는지 확인
3. **terraform.tfvars 생성**: 수집된 값들로 완전한 terraform.tfvars 파일 생성 (App2 전용 설정 포함)
4. **설정 확인**: 생성된 파일 내용을 출력하여 검토 가능

### 자동 수집되는 값들

- `project_name`: 프로젝트 이름 (walb2-app)
- `aws_region`: AWS 리전 
- `cluster_name`: EKS 클러스터 이름
- `vpc_id`: VPC ID

### App2 전용 기본 설정값들

- `service_account_name`: "aws-load-balancer-controller-app2"
- `namespace`: "kube-system"
- `ingress_class_name`: "alb-app2"
- `default_ingress_class`: false (App2는 기본 클래스가 아님)
- `chart_version`: "1.8.1"
- `replica_count`: 2
- `log_level`: "info"
- 리소스 제한 및 요청 설정
- 웹훅 설정

## 🔧 수동 설정

자동 생성된 `terraform.tfvars` 파일의 값들을 필요에 따라 수정할 수 있습니다:

```hcl
# 예시: 로그 레벨 변경
log_level = "debug"

# 예시: 복제본 수 변경  
replica_count = 3

# 예시: IngressClass 이름 변경
ingress_class_name = "alb-app2-custom"

# 예시: 리소스 제한 변경
resource_limits_cpu = "2000m"
resource_limits_memory = "4Gi"
```

## 🎯 App2 전용 특징

이 설정은 App2 전용으로 다음과 같은 특별한 구성을 가집니다:

1. **별도 ServiceAccount**: `aws-load-balancer-controller-app2`
2. **전용 IngressClass**: `alb-app2` (기본값 아님)
3. **구분된 태그**: `App = "App2"` 태그 추가
4. **독립적 운영**: App1과 독립적으로 운영되는 Load Balancer Controller

## 🗂️ 파일 구조

```
helm-lbc2/
├── generate-tfvars.sh          # terraform.tfvars 자동 생성 스크립트 (App2 전용)
├── terraform.tfvars.example    # 수동 설정용 예시 파일 (App2 전용)
├── terraform.tfvars           # 자동 생성된 설정 파일 (Git 제외)
├── main.tf                    # Helm 배포 Terraform 구성
├── variables.tf               # 변수 정의
├── outputs.tf                 # 출력 정의
├── providers.tf               # Provider 설정
└── USAGE.md                   # 이 파일
```

## ⚠️ 주의사항

1. **스크립트 실행 위치**: 반드시 `helm-lbc2` 디렉토리에서 실행
2. **인프라 선행 배포**: `../terraform2` 디렉토리의 인프라가 먼저 배포되어 있어야 함
3. **AWS 인증**: AWS CLI가 올바르게 설정되어 있어야 함
4. **jq 설치**: JSON 파싱을 위해 jq가 설치되어 있어야 함
5. **App2 전용**: 이 설정은 App2 전용이며 App1과 독립적으로 운영됩니다

## 🔄 App1 vs App2 차이점

| 구분 | App1 (helm-lbc) | App2 (helm-lbc2) |
|------|-----------------|------------------|
| ServiceAccount | aws-load-balancer-controller | aws-load-balancer-controller-app2 |
| IngressClass | alb (기본값) | alb-app2 (비기본값) |
| Terraform 소스 | ../terraform | ../terraform2 |
| 프로젝트명 | walb-app | walb2-app |

## 🐛 문제 해결

### "terraform.tfstate 파일을 찾을 수 없습니다"
- `../terraform2` 디렉토리에서 `terraform apply`를 먼저 실행하세요.

### "EKS 클러스터 이름을 가져올 수 없습니다"
- `../terraform2` 디렉토리에서 `terraform output eks_cluster_info` 명령어를 확인하세요.

### "VPC ID를 가져올 수 없습니다"  
- `../terraform2` 디렉토리에서 `terraform output vpc_info` 명령어를 확인하세요.

### jq 명령어가 없는 경우
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## 🔄 업데이트 시나리오

인프라가 변경된 경우:
1. `../terraform2` 디렉토리에서 `terraform apply` 실행
2. `./generate-tfvars.sh` 스크립트 재실행
3. `terraform plan`으로 변경사항 확인
4. `terraform apply`로 배포

## 🎯 Ingress 사용 예시

App2에서 ALB를 사용할 때는 다음과 같이 IngressClass를 지정하세요:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app2-ingress
  annotations:
    kubernetes.io/ingress.class: alb-app2  # App2 전용 IngressClass
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  ingressClassName: alb-app2  # App2 전용 IngressClass
  rules:
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. 스크립트 실행 로그의 에러 메시지
2. `../terraform2` 디렉토리의 terraform outputs
3. AWS CLI 인증 상태
4. 필요한 도구들의 설치 상태
5. App2 전용 설정이 올바른지 확인
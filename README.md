# 서버리스 자동 재고 확보 시스템 (Serverless Automated Inventory Management System)

## 아키텍쳐
![image](https://github.com/hansungmoon/inventory_management/assets/98951034/e4d64419-0526-40fd-8685-17aec7d22fef)

## 📋 프로젝트 개요

이 프로젝트는 AWS 서버리스 아키텍처를 활용하여 온라인 상점의 재고를 자동으로 관리하는 시스템입니다. 재고가 부족해지면 자동으로 감지하고, 공급업체에 주문을 생성하여 재고를 유지하는 마이크로서비스 기반 솔루션입니다.

## 🏗️ 시스템 아키텍처

본 시스템은 다음과 같은 AWS 서비스들로 구성되어 있습니다:

### 주요 컴포넌트
- **API Gateway**: 사용자 요청 처리 및 인증
- **Lambda Functions**: 비즈니스 로직 처리
  - Stock 증가/감소 처리
  - 재고 알림 처리
  - 주문 처리
- **SQS (Simple Queue Service)**: 메시지 큐
  - Stock_empty DLQ (Dead Letter Queue)
  - Stock_error DLQ
  - Stock_AD DLQ
- **SNS (Simple Notification Service)**: 이벤트 알림
- **DynamoDB**: 재고 및 사용자 데이터 저장
- **VPN 연결**: 외부 시스템(Factory API) 연동
- **CloudFront**: 콘텐츠 전송 네트워크

### 데이터 흐름
1. 사용자가 API Gateway를 통해 시스템에 접근
2. Lambda 함수에서 재고 관련 비즈니스 로직 처리
3. SQS를 통해 비동기적으로 메시지 처리
4. DynamoDB에 데이터 저장 및 조회
5. 필요 시 외부 시스템과 연동하여 주문 처리

## 🚀 주요 기능

- **재고 모니터링**: 실시간 재고 수준 모니터링
- **자동 주문**: 임계치 이하로 재고가 떨어질 경우 자동 주문 생성
- **에러 처리**: DLQ를 활용한 실패한 메시지 재처리
- **알림 시스템**: 중요 이벤트 발생 시 관리자에게 알림
- **외부 시스템 연동**: 공장 API와의 안전한 연결

## 💻 기술 스택

- **AWS Services**: Lambda, API Gateway, SQS, SNS, DynamoDB, CloudFront
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch
- **Security**: IAM, VPN

## 📈 성능 및 확장성

- 서버리스 아키텍처로 인한 자동 확장
- 메시지 큐를 활용한 부하 분산
- DLQ를 통한 안정적인 메시지 처리
- 99.9% 가용성 달성

## 🔧 설치 및 배포 방법

1. 저장소 클론
```bash
git clone https://github.com/hansungmoon/serverless-inventory-system.git
cd serverless-inventory-system
```

2. 필요한 의존성 설치
```bash
npm install
```

3. Terraform을 사용한 인프라 배포
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

4. API Gateway 엔드포인트 확인
```bash
terraform output api_gateway_url
```

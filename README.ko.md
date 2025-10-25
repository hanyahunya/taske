# Taske: When-Then 자동화 서비스

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/hanyahunya/taske)
[![Tech Stack](https://img.shields.io/badge/Tech-Spring%20Boot,%20Kafka,%20gRPC,%20MySQL,%20Redis-blueviolet)](https://github.com/hanyahunya/taske)

**Taske**는 **"When this happens (Trigger), then do that (Action)"** 방식의 자동화 워크플로우를 생성하고 관리할 수 있는 서비스입니다. MSA(Microservices Architecture)로 설계되어 각 기능이 독립적인 서비스로 분리되어 운영됩니다.

이 리포지토리는 Taske 프로젝트의 모든 마이크로서비스(`gateway`, `auth`, `user`, `task`, `worker`, `integration`)를 Git Submodule로 통합하고, Docker 기반의 배포 환경 설정을 포함하고 있습니다.

---

##  프로젝트 목표 및 특징

* **반복 작업 자동화**: 사용자는 다양한 서비스(예: Google Drive, Slack, Email 등)를 연결하여 "만약 ~하면, ~한다" 형태의 규칙(Task)을 정의하고, 이를 통해 반복적인 작업을 자동화할 수 있습니다.
* **MSA 구조**: 각 도메인(인증, 유저 정보, 작업 관리, 작업 실행 등)을 별도의 마이크로서비스로 분리하여 **독립적인 개발, 배포, 확장**이 가능합니다. 서비스 간 통신은 **Kafka** (비동기 이벤트)와 **gRPC** (동기 요청-응답)를 활용합니다.
* **높은 확장성**: 새로운 자동화 기능(Trigger/Action 모듈)을 추가할 때, 핵심 로직 변경 없이 **데이터베이스에 모듈 정의(API 명세, 파라미터 스키마 등)를 추가**하는 것만으로 확장이 가능하도록 설계되었습니다. 이는 서비스의 유연성과 유지보수성을 크게 향상시킵니다.
* **안정적인 실행**: Kafka를 이용한 이벤트 기반 아키텍처를 통해 서비스 간의 의존성을 낮추고, 특정 서비스의 장애가 전체 시스템에 미치는 영향을 최소화합니다.

---

##  아키텍처 및 서비스 역할

Taske는 다음과 같은 마이크로서비스로 구성됩니다.

1.  **Gateway Service**: [Gateway](https://github.com/hanyahunya/taske_gateway)
    * **역할**: 외부(프론트엔드) 요청의 **진입점(API Gateway)** 역할.
    * **주요 기능**: 요청 라우팅, **액세스 토큰 유효성 검사 (인증)**, 로드 밸런싱, 공통 CORS 처리 등.
    * **기술 스택**: Spring Cloud Gateway (WebFlux - Netty 기반 비동기 처리).

2.  **Auth Service**: [Auth](https://github.com/hanyahunya/taske_auth)
    * **역할**: 사용자 **인증 및 권한 부여** 총괄.
    * **주요 기능**: 일반 회원가입/로그인, 소셜 로그인(Google 등), **JWT (Access/Refresh Token) 발급 및 갱신**, 보안 관련 DB 관리 (ID, 암호화된 비밀번호, 소셜 연동 정보 등).
    * **기술 스택**: Spring Boot, Spring Security, JPA, MySQL, Redis (토큰/임시 정보 저장), Kafka (이벤트 발행).

3.  **User Service**: [User](https://github.com/hanyahunya/taske_user)
    * **역할**: 인증 정보를 제외한 **사용자 정보 관리**.
    * **주요 기능**: 사용자 프로필 정보(국가/지역 등) 관리. (현재는 비중이 낮음)

4.  **Task Service**: [Task](https://github.com/hanyahunya/taske_task)
    * **역할**: **자동화 작업(Task) 및 모듈 관리**의 핵심.
    * **주요 기능**:
        * 사용 가능한 자동화 모듈(Module_capabilitiy - Trigger,Action) 정의 조회.
        * 사용자 Task 생성, 조회, 수정, 삭제 (CRUD).
        * **Task Trigger 관리**: 스케줄링(Cron), 웹훅 수신, 외부 API 폴링 등 Trigger 조건 감지 및 **이벤트 발행 (Kafka)**.
        * 관리자 기능: 신규 자동화 모듈 등록/수정/삭제.

5.  **Worker Service**: [Worker](https://github.com/hanyahunya/taske_worker)
    * **역할**: Task Service로부터 Trigger 발동 이벤트를 받아 **실제 Action 실행 오케스트레이션** 담당.
    * **주요 기능**:
        * Kafka로부터 `TriggerFiredEvent` 구독.
        * Task Service에 gRPC 요청하여 실행할 Action 목록 및 상세 정보 조회.
        * Action 정의에 따라 순차적으로 실행 (내부 로직 수행 또는 Integration Service에 외부 API 요청 위임).
        * Action 실행 결과(Output)를 다음 Action의 입력(Input)으로 전달하기 위한 컨텍스트 관리.

6.  **Integration Service**: [Integration](https://github.com/hanyahunya/taske_integration)
    * **역할**: **외부 서비스와의 연동** 처리 전문.
    * **주요 기능**:
        * 소셜 로그인 시 외부 OAuth 서비스와 통신하여 토큰 발급 및 사용자 정보 검증.
        * Worker Service의 요청을 받아 외부 API(GCP, AWS 등) 호출 수행.
        * 외부 서비스 인증 정보(API Key, OAuth Token 등)의 **안전한 저장 및 관리** (암호화).

---

## 워크플로우 예시: 자동화 Task 실행 과정

다음은 사용자가 등록한 Task가 실행되는 과정의 예시입니다.

**Task 정의:** *"매주 월요일 아침 9시에 Google Drive의 '팀 공유' 폴더를 스캔하여 지난주에 수정된 '기획서' 파일 목록을 Slack의 '기획팀' 채널로 자동으로 전송한다."*

1.  **[Task Service] Trigger 감지**:
    * Task Service의 스케줄러가 매주 월요일 오전 9시가 되었음을 감지합니다.
    * 해당 Trigger 조건에 맞는 Task 정보를 확인하고, Kafka로 `TriggerFiredEvent`를 발행합니다. (Payload: 사용자 ID, Task ID, Trigger 기본 정보 등)

2.  **[Worker Service] 이벤트 수신 및 Action 실행 준비**:
    * Worker Service는 Kafka로부터 `TriggerFiredEvent`를 구독하여 수신합니다.
    * Task ID를 이용해 Task Service에 gRPC로 **Action 실행 정보(순서, 설정값, API 명세 등)를 요청**합니다.

3.  **[Worker Service] Action 1 실행**:
    * 첫 번째 Action인 "Google Drive 파일 목록 조회"를 실행합니다.
    * 이 Action은 외부 Google API 호출이 필요하므로, **Integration Service에 gRPC로 API 요청을 위임**합니다. (Payload: 사용자 인증 정보 식별자, 폴더 ID, 검색 조건 등)
    * **[Integration Service]** 는 암호화된 사용자 Google 인증 정보를 조회하여 Google Drive API를 호출하고, 결과를 Worker Service에 반환합니다.
    * Worker Service는 Action 1의 결과(파일 목록)를 **내부 실행 컨텍스트에 저장**합니다. (`action1.output.fileList = [...]`)

4.  **[Worker Service] Action 2 실행**:
    * 두 번째 Action인 "Slack 메시지 전송"을 실행합니다.
    * Action 설정값에 `{{action1.output.fileList}}` 와 같은 **변수**가 포함되어 있을 수 있습니다. Worker Service는 실행 컨텍스트의 값으로 이 변수를 치환합니다. (예: "지난주 수정된 기획서 목록: [파일1.docx, 파일2.pptx]")
    * 치환된 데이터를 포함하여 **Integration Service에 gRPC, kafka로 Slack API 요청을 위임**합니다.
    * **[Integration Service]** 는 Slack API를 호출하여 메시지를 전송하고, 결과를 Worker Service에 반환합니다.
    * Worker Service는 Action 2의 결과를 실행 컨텍스트에 저장합니다.

5.  **[Worker Service] Task 실행 완료**:
    * 모든 Action 실행이 완료되면 Task 실행을 종료합니다.

---

## 기술적 강점

* **MSA 설계 및 구현 역량**: 각 서비스의 역할을 명확히 분리하고, 서비스 간 상호작용(동기/비동기)을 효율적으로 설계하여 복잡한 시스템을 관리 가능한 단위로 구축했습니다.

* **이벤트 기반 아키텍처 (Kafka)**: 서비스 간 결합도를 낮추고 비동기 처리를 통해 시스템의 탄력성과 확장성을 확보했습니다. 특히, Trigger 발동(`Task` -> `Worker`), 응답데이터가 필요없는 요청(`Worker` -> `외부 api`) 등 핵심 워크플로우에 Kafka를 적용하여 안정적인 데이터 흐름을 구현했습니다.

* **gRPC를 활용한 효율적인 서비스 간 통신**: MSA 내부의 동기 통신에는 Protocol Buffers 기반의 gRPC를 사용하여 HTTP/REST 대비 성능 이점을 확보하고, 명확한 인터페이스 정의를 통해 서비스 간 연동 오류를 줄였습니다. (`Worker` <-> `Task`, `Worker` <-> `Integration`)

* **DB 기반 모듈 정의를 통한 뛰어난 확장성**: 새로운 외부 서비스 연동이나 자동화 기능을 추가할 때, 코드 변경을 최소화하고 
**데이터베이스에 모듈의 API 명세(URL, Method, 파라미터 스키마, 인증 방식 등)를 정의**하는 것만으로 확장이 가능하도록 설계했습니다. 이는 신규 기능 개발 속도를 높이고 유지보수 비용을 절감하는 핵심적인 설계입니다. ([task-schema](https://github.com/hanyahunya/taske/blob/main/docker/mysql/init-scripts/07-task-schema.sql) 참조)

* **인증 및 보안**: Spring Security를 활용하여 API Gateway(`gateway`)에서의 토큰 기반 인증 및 각 서비스에서의 인가 처리를 구현했습니다. JWT Access Token/Refresh Token 발급 및 재발급 로직, 소셜 로그인 연동, 외부 API 인증 정보 암호화(`integration`) 등 보안적인 측면을 고려하여 설계했습니다.

* **Docker 기반 배포 환경**: `docker-compose.yml` 파일을 통해 전체 MSA 환경을 서버에서 일관되게 구축하고 실행할 수 있도록 구성하여 개발 및 배포 편의성을 높였습니다. 현재는 개발 단계이므로 Docker Compose + 온프레미스 환경이지만, 추후 모듈이 많아지고 실제 배포할 퀄리티가 되면 Kubernetes와 AWS 클라우드 서비스를 이용하여 배포할 예정입니다.

**더 자세한 기술적 구현 내용은 각 서비스의 서브모듈 리포지토리에서 확인하실 수 있습니다.**

---

## 서비스 접속 (Service Access)

현재 Taske 서비스는 아래 URL에서 접속할 수 있습니다.

[https://hanyahunya.com/taske](https://hanyahunya.com/taske)

---


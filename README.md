# Taske: When-Then 自動化サービス

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/hanyahunya/taske)
[![Tech Stack](https://img.shields.io/badge/Tech-Spring%20Boot,%20Kafka,%20gRPC,%20MySQL,%20Redis-blueviolet)](https://github.com/hanyahunya/taske)

**Taske**は**「もし～なら (Trigger)、～する (Action)」**方式の自動化ワークフローを作成・管理できるサービスです。MSA(Microservices Architecture)で設計されており、各機能が独立したサービスとして分離・運用されます。

このリポジトリは、Taskeプロジェクトの全てのマイクロサービス(`gateway`, `auth`, `user`, `task`, `worker`, `integration`)をGit Submoduleとして統合し、Dockerベースのデプロイ環境設定を含んでいます。

---

##  プロジェクトの目標と特徴

* **反復作業の自動化**: ユーザーは様々なサービス（例：Google Drive, Slack, Emailなど）を連携させ、「もし～なら、～する」という形式のルール(Task)を定義し、これを通じて反復的な作業を自動化できます。
* **MSA構造**: 各ドメイン（認証、ユーザー情報、タスク管理、タスク実行など）を個別のマイクロサービスとして分離し、**独立した開発、デプロイ、拡張**を可能にします。サービス間の通信には**Kafka**（非同期イベント）と**gRPC**（同期リクエスト-レスポンス）を活用します。
* **高い拡張性**: 新しい自動化機能（Trigger/Actionモジュール）を追加する際、コアロジックの変更なしに**データベースにモジュール定義（API仕様、パラメータスキーマなど）を追加**するだけで拡張が可能になるように設計されています。これにより、サービスの柔軟性と保守性が大幅に向上します。
* **安定した実行**: Kafkaを利用したイベント駆動型アーキテクチャを通じて、サービス間の依存性を低減し、特定のサービスの障害がシステム全体に与える影響を最小限に抑えます。

---

##  アーキテクチャとサービスの役割

Taskeは以下のマイクロサービスで構成されています。

1.  **Gateway Service**: [Gateway](https://github.com/hanyahunya/taske_gateway)
    * **役割**: 外部（フロントエンド）リクエストの**エントリポイント(API Gateway)**の役割。
    * **主な機能**: リクエストルーティング、**アクセストークンの有効性検証（認証）**、ロードバランシング、共通CORS処理など。
    * **技術スタック**: Spring Cloud Gateway (WebFlux - Nettyベースの非同期処理)。

2.  **Auth Service**: [Auth](https://github.com/hanyahunya/taske_auth)
    * **役割**: ユーザー**認証と権限付与**を統括。
    * **主な機能**: 一般会員登録/ログイン、ソーシャルログイン（Googleなど）、**JWT（Access/Refresh Token）の発行と更新**、セキュリティ関連DB管理（ID、暗号化されたパスワード、ソーシャル連携情報など）。
    * **技術スタック**: Spring Boot, Spring Security, JPA, MySQL, Redis（トークン/一時情報保存）、Kafka（イベント発行）。

3.  **User Service**: [User](https://github.com/hanyahunya/taske_user)
    * **役割**: 認証情報を除く**ユーザー情報管理**。
    * **主な機能**: ユーザープロファイル情報（国/地域など）管理。（現在は重要度が低い）

4.  **Task Service**: [Task](https://github.com/hanyahunya/taske_task)
    * **役割**: **自動化タスク(Task)とモジュール管理**の核心。
    * **主な機能**:
        * 利用可能な自動化モジュール(Module_capability - Trigger,Action)定義の照会。
        * ユーザーTaskの作成、照会、修正、削除（CRUD）。
        * **Task Trigger管理**: スケジューリング(Cron)、Webhook受信、外部APIポーリングなど、Trigger条件の検知と**イベント発行（Kafka）**。
        * 管理者機能: 新規自動化モジュールの登録/修正/削除。

5.  **Worker Service**: [Worker](https://github.com/hanyahunya/taske_worker)
    * **役割**: Task ServiceからTrigger発動イベントを受け取り、**実際のAction実行オーケストレーション**を担当。
    * **主な機能**:
        * Kafkaから`TriggerFiredEvent`を購読。
        * Task ServiceにgRPCリクエストを送り、実行するActionリストと詳細情報を照会。
        * Action定義に従って順次実行（内部ロジック実行またはIntegration Serviceへの外部APIリクエスト委任）。
        * Action実行結果（Output）を次のActionの入力（Input）として渡すためのコンテキスト管理。

6.  **Integration Service**: [Integration](https://github.com/hanyahunya/taske_integration)
    * **役割**: **外部サービスとの連携**処理専門。
    * **主な機能**:
        * ソーシャルログイン時に外部OAuthサービスと通信し、トークン発行とユーザー情報検証。
        * Worker Serviceのリクエストを受け、外部API（GCP、AWSなど）呼び出しを実行。
        * 外部サービス認証情報（API Key、OAuth Tokenなど）の**安全な保存と管理**（暗号化）。

---

## ワークフロー例: 自動化Taskの実行プロセス

以下は、ユーザーが登録したTaskが実行されるプロセスの例です。

**Task定義:** *「毎週月曜日の朝9時にGoogle Driveの「チーム共有」フォルダをスキャンし、先週修正された「企画書」ファイルリストをSlackの「企画チーム」チャンネルに自動送信する。」*

1.  **[Task Service] Trigger検知**:
    * Task Serviceのスケジューラーが毎週月曜日の午前9時になったことを検知します。
    * 該当するTrigger条件に合うTask情報を確認し、Kafkaに`TriggerFiredEvent`を発行します。（Payload: ユーザーID、Task ID、Trigger基本情報など）

2.  **[Worker Service] イベント受信とAction実行準備**:
    * Worker ServiceはKafkaから`TriggerFiredEvent`を購読して受信します。
    * Task IDを利用してTask ServiceにgRPCで**Action実行情報（順序、設定値、API仕様など）をリクエスト**します。

3.  **[Worker Service] Action 1 実行**:
    * 最初のActionである「Google Driveファイルリスト照会」を実行します。
    * このActionは外部Google API呼び出しが必要なため、**Integration ServiceにgRPCでAPIリクエストを委任**します。（Payload: ユーザー認証情報識別子、フォルダID、検索条件など）
    * **[Integration Service]** は暗号化されたユーザーのGoogle認証情報を照会し、Google Drive APIを呼び出して結果をWorker Serviceに返します。
    * Worker ServiceはAction 1の結果（ファイルリスト）を**内部実行コンテキストに保存**します。（`action1.output.fileList = [...]`）

4.  **[Worker Service] Action 2 実行**:
    * 2番目のActionである「Slackメッセージ送信」を実行します。
    * Action設定値に `{{action1.output.fileList}}` のような**変数**が含まれている場合があります。Worker Serviceは実行コンテキストの値でこの変数を置換します。（例：「先週修正された企画書リスト：[ファイル1.docx, ファイル2.pptx]」）
    * 置換されたデータを含めて**Integration ServiceにgRPC, kafkaでSlack APIリクエストを委任**します。
    * **[Integration Service]** はSlack APIを呼び出してメッセージを送信し、結果をWorker Serviceに返します。
    * Worker ServiceはAction 2の結果を実行コンテキストに保存します。

5.  **[Worker Service] Task実行完了**:
    * 全てのAction実行が完了したらTask実行を終了します。

---

## 技術的強み

* **MSA設計・実装能力**: 各サービスの役割を明確に分離し、サービス間の相互作用（同期/非同期）を効率的に設計することで、複雑なシステムを管理可能な単位で構築しました。

* **イベント駆動型アーキテクチャ (Kafka)**: サービス間の結合度を下げ、非同期処理を通じてシステムの弾力性と拡張性を確保しました。特に、Trigger発動（`Task` -> `Worker`）、レスポンスデータが不要なリクエスト（`Worker` -> `外部API`）など、核心的なワークフローにKafkaを適用し、安定したデータフローを実現しました。

* **gRPCを活用した効率的なサービス間通信**: MSA内部の同期通信にはProtocol BuffersベースのgRPCを使用し、HTTP/RESTに比べてパフォーマンス上の利点を確保し、明確なインターフェース定義を通じてサービス間の連携エラーを削減しました。（`Worker` <-> `Task`, `Worker` <-> `Integration`）

* **DBベースのモジュール定義による優れた拡張性**: 新しい外部サービス連携や自動化機能を追加する際、コード変更を最小限に抑え、**データベースにモジュールのAPI仕様（URL, Method, パラメータスキーマ, 認証方式など）を定義**するだけで拡張が可能になるように設計しました。これは新規機能開発の速度を高め、保守コストを削減する核心的な設計です。（[task-schema](https://github.com/hanyahunya/taske/blob/main/docker/mysql/init-scripts/07-task-schema.sql) 参照）

* **認証とセキュリティ**: Spring Securityを活用し、API Gateway（`gateway`）でのトークンベース認証と各サービスでの認可処理を実装しました。JWT Access Token/Refresh Tokenの発行・再発行ロジック、ソーシャルログイン連携、外部API認証情報の暗号化（`integration`）など、セキュリティ面を考慮して設計しました。

* **Dockerベースのデプロイ環境**: `docker-compose.yml`ファイルを通じて、MSA全体の環境をサーバーで一貫して構築・実行できるように構成し、開発とデプロイの利便性を高めています。現在は開発段階のためDocker Compose + オンプレミス環境ですが、将来的にモジュールが増え、本番デプロイの品質に達した際には、KubernetesとAWSクラウドサービスを利用してデプロイする予定です。

**より詳細な技術的実装内容は、各サービスのサブモジュールリポジトリでご確認いただけます。**

---

## サービスアクセス (Service Access)

現在デプロイされている Taske サービスは、以下の URL からアクセスできます。

[https://hanyahunya.com/taske](https://hanyahunya.com/taske)

---
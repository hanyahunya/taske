SET NAMES 'utf8mb4';

USE taske_task;

-- cron 트리거 모듈
INSERT INTO module_capabilities (
    capability_id, 
    module_id, 
    capability_type, 
    name, 
    description, 
    required_scopes, 
    execution_type, 
    execution_spec, 
    param_schema, 
    output_schema
    )
VALUES
    (
        'schedule_cron',
        'SYSTEM',
        'TRIGGER',
        '%_ko_%예약 실행%_ja_%定期実行%_en_%Scheduled Run',
        '%_ko_%지정한 시간과 요일에 작업을 주기적으로 실행합니다.%_ja_%指定した時間と曜日にタスクを定期的に実行します。%_en_%Runs the task periodically at the specified time and days of the week.',
        '[]',
        'SCHEDULING',
        '{
            "topic": "system-mail-events",
            "method": "",
            "querySchema": [],
            "bodySchema": [],
            "headerSchema": []
        }',
        '{
            "type": "object",
            "properties": {
                "cron": {
                    "type": "string",
                    "description": "%_ko_%작업을 실행할 시간과 요일을 지정합니다.%_ja_%タスクを実行する時間と曜日を指定します。%_en_%Specifies the time and days of the week to run the task."
                }
            },
            "ignored" : [],
            "required": ["cron"]
        }',
        '{
            "properties": {},
            "ignored": []
        }'
    );

-- 메일 전송 액션 모듈
INSERT INTO module_capabilities (
    capability_id, 
    module_id, 
    capability_type, 
    name, 
    description, 
    required_scopes, 
    execution_type, 
    execution_spec, 
    param_schema, 
    output_schema, 
    dependency
    )
VALUES
    (
        'system-send-email',
        'SYSTEM',
        'ACTION',
        '%_ko_%이메일 전송%_ja_%Eメール送信%_en_%Send Email',
        '%_ko_%지정된 수신자에게 이메일을 전송합니다. HTML 본문을 사용할 수 있으며, 동적 변수를 지원합니다.%_ja_%指定された受信者にEメールを送信します。 HTML本文が使用可能で、動的変数をサポートします。%_en_%Sends an email to the specified recipients. Supports HTML body and dynamic variables.',
        '[]',
        'INTERNAL',
        '{
            "topic": "system-mail-events",
            "method": "",
            "querySchema": ["#_locale"],
            "bodySchema": ["to", "subject", "htmlBody"],
            "headerSchema": []
        }',
        '{
            "type": "object",
            "properties": {
                "to": {
                    "type": "array",
                    "items": {
                        "type": "string",
                        "format": "email",
                        "description": "%_ko_%추가할 이메일 주소를 입력하세요%_ja_%追加するEメールアドレスを入力してください%_en_%Enter an email address to add"
                    },
                    "description": "%_ko_%메일을 수신할 사람들의 이메일 주소 목록%_ja_%メールを受信する人々のEメールアドレス一覧%_en_%List of email addresses to receive the mail"
                },
                "subject": {
                    "type": "string",
                    "description": "%_ko_%이메일 제목%_ja_%Eメールの件名%_en_%Email subject"
                },
                "htmlBody": {
                    "type": "string",
                    "description": "%_ko_%HTML 형식의 이메일 본문%_ja_%HTML形式のEメール本文%_en_%Email body in HTML format"
                },
                "#_locale": {
                    "type": "string",
                    "value": "ko-KR"
                }
            },
            "ignored": ["#_locale"],
            "required": ["to", "subject", "htmlBody"]
        }',
        '{
            "properties": {
                "success": {
                    "type": "boolean",
                    "name": "%_ko_%성공 여부%_ja_%成功可否%_en_%Success Status",
                    "description": "%_ko_%이메일 전송 성공 여부%_ja_%Eメール送信の成功可否%_en_%Email send success status"
                },
                "messageId": {
                    "type": "string",
                    "name": "%_ko_%메시지 ID%_ja_%メッセージID%_en_%Message ID",
                    "description": "%_ko_%성공적으로 전송된 이메일의 고유 ID%_ja_%正常に送信されたEメールの固有ID%_en_%Unique ID of the successfully sent email"
                }
            },
            "ignored": ["messageId"]
        }',
        '{}'
    );


-- 기상청 기상예보 모듈
-- INSERT INTO module_capabilities (capability_id, module_id, capability_type, name, description, required_scopes, execution_type, execution_spec, param_schema, output_schema, dependency)
-- VALUES
--     (
--         'kma-get-forecast',
--         'SYSTEM',
--         'ACTION',
--         '%_ko_%기상청 단기 예보 조회%_ja_%気象庁短期予報照会%_en_%KMA Short-term Forecast',
--         '%_ko_%X, Y 좌표와 기준 시각을 이용해 날씨 예보를 조회합니다.%_ja_%X、Y座標と基準時刻を利用して天気予報を照会します。%_en_%Fetches weather forecast using X, Y coordinates and base time.',
--         '[]',
--         'HTTP_REQUEST',
--         '{
--             "topic": "",
--             "method": "GET",
--             "endpoint" : "https://apihub.kma.go.kr/api/typ02/openApi/VilageFcstInfoService_2.0/getVilageFcst",
--             "querySchema": [],
--             "bodySchema": [],
--             "headerSchema": []
--         }',
--         '{
--             "type": "object",
--             "properties": {
--                 "lon": {
--                     "type": "string",
--                     "description": "%_ko_%조회할 X 좌표%_ja_%照会するX座標%_en_%X coordinate to fetch"
--                 },
--                 "lat": {
--                     "type": "string",
--                     "description": "%_ko_%조회할 Y 좌표%_ja_%照会するY座標%_en_%Y coordinate to fetch"
--                 },
--                 "base_date": {
--                     "type": "string",
--                     "description": "%_ko_%HTML 형식의 이메일 본문%_ja_%HTML形式のEメール本文%_en_%Email body in HTML format"
--                 },
--                 "#_pageNo": {
--                     "type": "string",
--                     "value": "1"
--                 },
--                 "#_dataType": {
--                     "type": "string",
--                     "value": "JSON"
--                 },
--                 "#_numOfRows": {
--                     "type": "string",
--                     "value": "181"
--                 },
--                 "#_base_time": {
--                     "type": "string",
--                     "value": "0800"
--                 },
--                 "%_nx": {
--                     "type": "string",
--                     "value": "디펜던시 id.output.x"
--                 },
--                 "%_ny": {
--                     "type": "string",
--                     "value": "디펜던시 id.output.y"
--                 },
--                 "$_authKey": {
--                     "type": "string",
--                     "value": "apihub.kma.go.kr.secret"
--                 },
--             },
--             "ignored": ["#_pageNo", "#_dataType", "#_numOfRows", "#_base_time", "%_nx", "%_ny", "$_authKey"],
--             "required": ["lon", "lat", "base_date"]
--         }',
--         '{
--             "properties": {
--                 "success": {
--                     "type": "boolean",
--                     "name": "%_ko_%성공 여부%_ja_%成功可否%_en_%Success Status",
--                     "description": "%_ko_%이메일 전송 성공 여부%_ja_%Eメール送信の成功可否%_en_%Email send success status"
--                 },
--                 "messageId": {
--                     "type": "string",
--                     "name": "%_ko_%메시지 ID%_ja_%メッセージID%_en_%Message ID",
--                     "description": "%_ko_%성공적으로 전송된 이메일의 고유 ID%_ja_%正常に送信されたEメールの固有ID%_en_%Unique ID of the successfully sent email"
--                 }
--             },
--             "ignored": ["messageId"]
--         }',
--         '{
--             "capability_id": "",
--             /* 2. CapS의 param_schema에 값을 매핑하는 방법 */
--             "input_mapping": {
--                 /* CapS의 "lat" 에는 -> 이 액션(CapM)의 "lat" 값을 전달 */
--                 "lat": "#_%self.param.lat%_#",
--                 /* CapS의 "lon" 에는 -> 이 액션(CapM)의 "lon" 값을 전달 */
--                 "lon": "#_%self.param.lon%_#"
--             },

--             /* 3. CapS의 output을 CapM의 param_schema에 매핑하는 방법 */
--             "output_mapping": {
--                 /* 이 액션(CapM)의 "#_x" 에는 -> CapS의 "x" 출력값을 전달 */
--                 "#_x": "#_%dependency.output.x%_#",
--                 /* 이 액션(CapM)의 "#_y" 에는 -> CapS의 "y" 출력값을 전달 */
--                 "#_y": "#_%dependency.output.y%_#"
--             }
--         }'
--     );
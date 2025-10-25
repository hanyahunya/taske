USE taske_task;

CREATE TABLE `tasks` (
  `task_id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `is_active` bit(1) NOT NULL DEFAULT b'1',
  `task_name` varchar(255) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  `user_id` binary(16) NOT NULL,
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `modules` (
  `module_id` enum('GOOGLE','SYSTEM') NOT NULL,
  `api_base_url` varchar(255) DEFAULT NULL,
  `auth_type` enum('API_KEY','OAUTH2') DEFAULT NULL,
  `module_name` varchar(100) NOT NULL,
  PRIMARY KEY (`module_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `module_capabilities` (
  `capability_id` varchar(100) NOT NULL,
  `capability_type` enum('ACTION','TRIGGER') NOT NULL,
  `dependency` json DEFAULT NULL,
  `description` text,
  `execution_spec` json DEFAULT NULL,
  `execution_type` enum('HTTP_POLLING','HTTP_REQUEST','INTERNAL','SCHEDULING','WEBHOOK') NOT NULL,
  `name` varchar(255) NOT NULL,
  `output_schema` json DEFAULT NULL,
  `param_schema` json DEFAULT NULL,
  `required_scopes` json DEFAULT NULL,
  `module_id` enum('GOOGLE','SYSTEM') NOT NULL,
  PRIMARY KEY (`capability_id`),
  KEY `idx_capability_type_execution_type` (`capability_type`,`execution_type`),
  KEY `FKjddr3ebcsxqaeos09f6wifwal` (`module_id`),
  CONSTRAINT `FKjddr3ebcsxqaeos09f6wifwal` FOREIGN KEY (`module_id`) REFERENCES `modules` (`module_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `triggers` (
  `trigger_id` bigint NOT NULL AUTO_INCREMENT,
  `trigger_config` json DEFAULT NULL,
  `capability_id` varchar(100) NOT NULL,
  `task_id` bigint NOT NULL,
  PRIMARY KEY (`trigger_id`),
  UNIQUE KEY `UKneg803jt2ta9ficowld83ffna` (`task_id`),
  KEY `FK44nqa29l1pef1n2gs3qtgomyg` (`capability_id`),
  CONSTRAINT `FK44nqa29l1pef1n2gs3qtgomyg` FOREIGN KEY (`capability_id`) REFERENCES `module_capabilities` (`capability_id`),
  CONSTRAINT `FKmhotstas0pk3okmwjbivwqfdl` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `actions` (
  `action_id` bigint NOT NULL AUTO_INCREMENT,
  `action_config` json DEFAULT NULL,
  `execution_order` int NOT NULL,
  `capability_id` varchar(100) NOT NULL,
  `task_id` bigint NOT NULL,
  PRIMARY KEY (`action_id`),
  KEY `FKh5lsrvl30586lruaqyqmpcnt6` (`capability_id`),
  KEY `FKdnlvgs6w6lxsj6t1dqb1dqa0s` (`task_id`),
  CONSTRAINT `FKdnlvgs6w6lxsj6t1dqb1dqa0s` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`task_id`) ON DELETE CASCADE,
  CONSTRAINT `FKh5lsrvl30586lruaqyqmpcnt6` FOREIGN KEY (`capability_id`) REFERENCES `module_capabilities` (`capability_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
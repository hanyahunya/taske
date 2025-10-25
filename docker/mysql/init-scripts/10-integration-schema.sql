USE taske_integration;

CREATE TABLE `social_credentials` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `encrypted_access_token` text NOT NULL,
  `encrypted_refresh_token` text,
  `expires_at` datetime(6) DEFAULT NULL,
  `provider` enum('GITHUB','GOOGLE') NOT NULL,
  `provider_sub` varchar(255) NOT NULL,
  `scopes` text,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider_sub` (`provider`,`provider_sub`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
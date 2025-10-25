USE taske_user;

CREATE TABLE `users` (
  `user_id` binary(16) NOT NULL,
  `country` varchar(32) DEFAULT NULL DEFAULT 'ko-KR',
  `email` varchar(255) DEFAULT NULL,
  `signuped_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
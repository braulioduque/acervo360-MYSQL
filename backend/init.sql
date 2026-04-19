-- Script de Inicialização Acervo360 - MySQL
-- Garantindo paridade total com o esquema original do Supabase

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Profiles
CREATE TABLE IF NOT EXISTS `profiles` (
  `id` varchar(36) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `cpf` varchar(20) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `cr_number` varchar(50) DEFAULT NULL,
  `cr_categories` json DEFAULT NULL,
  `cr_valid_until` date DEFAULT NULL,
  `avatar_url` varchar(255) DEFAULT NULL,
  `cr_url` varchar(255) DEFAULT NULL,
  `is_admin` varchar(1) DEFAULT 'N',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `cpf` (`cpf`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. Clubs
CREATE TABLE IF NOT EXISTS `clubs` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `document_number` varchar(50) DEFAULT NULL,
  `cnpj` varchar(20) DEFAULT NULL,
  `cr_number` varchar(50) DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL,
  `number` varchar(20) DEFAULT NULL,
  `complement` varchar(100) DEFAULT NULL,
  `neighborhood` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(2) DEFAULT NULL,
  `logo_url` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_user_id` (`owner_user_id`),
  CONSTRAINT `clubs_ibfk_1` FOREIGN KEY (`owner_user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. Firearms
CREATE TABLE IF NOT EXISTS `firearms` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `brand` varchar(100) DEFAULT NULL,
  `model` varchar(100) DEFAULT NULL,
  `caliber` varchar(50) DEFAULT NULL,
  `sigma_number` varchar(100) DEFAULT NULL,
  `craf_number` varchar(100) DEFAULT NULL,
  `craf_valid_until` date DEFAULT NULL,
  `avatar_url` varchar(255) DEFAULT NULL,
  `craf_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_user_id` (`owner_user_id`),
  CONSTRAINT `firearms_ibfk_1` FOREIGN KEY (`owner_user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. Habituality Modalities
CREATE TABLE IF NOT EXISTS `habituality_modalities` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. Habitualities
CREATE TABLE IF NOT EXISTS `habitualities` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `event_name` varchar(255) DEFAULT NULL,
  `modality` varchar(100) DEFAULT NULL,
  `modality_other` varchar(100) DEFAULT NULL,
  `date_realization` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `club_id` varchar(36) DEFAULT NULL,
  `location_name` varchar(255) DEFAULT NULL,
  `equipment_source` varchar(50) DEFAULT NULL,
  `firearm_id` varchar(36) DEFAULT NULL,
  `third_party_type` varchar(50) DEFAULT NULL,
  `third_party_brand` varchar(100) DEFAULT NULL,
  `third_party_species` varchar(100) DEFAULT NULL,
  `third_party_caliber_type` varchar(50) DEFAULT NULL,
  `third_party_caliber` varchar(50) DEFAULT NULL,
  `ammo_source` varchar(50) DEFAULT NULL,
  `shot_count` int DEFAULT '0',
  `attachment_url` varchar(255) DEFAULT NULL,
  `book_page` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_user_id` (`owner_user_id`),
  CONSTRAINT `habitualities_ibfk_1` FOREIGN KEY (`owner_user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. Profile Addresses
CREATE TABLE IF NOT EXISTS `profile_addresses` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `address_type` varchar(50) DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL,
  `number` varchar(20) DEFAULT NULL,
  `complement` varchar(100) DEFAULT NULL,
  `neighborhood` varchar(100) DEFAULT NULL,
  `state_code` varchar(2) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `postal_code` varchar(15) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `profile_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Gtes
CREATE TABLE IF NOT EXISTS `gtes` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `firearm_id` varchar(36) NOT NULL,
  `profile_address_id` varchar(36) NOT NULL,
  `destination_club_id` varchar(36) NOT NULL,
  `protocol_number` varchar(50) DEFAULT NULL,
  `issued_at` date DEFAULT NULL,
  `expires_at` date DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `gte_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner_user_id` (`owner_user_id`),
  KEY `firearm_id` (`firearm_id`),
  KEY `profile_address_id` (`profile_address_id`),
  KEY `destination_club_id` (`destination_club_id`),
  CONSTRAINT `gtes_ibfk_1` FOREIGN KEY (`owner_user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gtes_ibfk_2` FOREIGN KEY (`firearm_id`) REFERENCES `firearms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gtes_ibfk_3` FOREIGN KEY (`profile_address_id`) REFERENCES `profile_addresses` (`id`),
  CONSTRAINT `gtes_ibfk_4` FOREIGN KEY (`destination_club_id`) REFERENCES `clubs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 8. Subscription Plans
CREATE TABLE IF NOT EXISTS `subscription_plans` (
  `id` varchar(50) NOT NULL,
  `plan_key` varchar(50) NOT NULL,
  `title` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `period_label` varchar(50) DEFAULT NULL,
  `months_count` int DEFAULT '0',
  `subtitle_override` text,
  `badge` varchar(50) DEFAULT NULL,
  `is_recommended` tinyint(1) DEFAULT '0',
  `icon_name` varchar(50) DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 9. User Subscriptions
CREATE TABLE IF NOT EXISTS `user_subscriptions` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `plan` varchar(50) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime DEFAULT NULL,
  `status` varchar(20) DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `user_subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 10. User Clubs
CREATE TABLE IF NOT EXISTS `user_clubs` (
  `id` varchar(36) NOT NULL,
  `user_id` varchar(36) NOT NULL,
  `club_id` varchar(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `club_id` (`club_id`),
  CONSTRAINT `user_clubs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `profiles` (`id`),
  CONSTRAINT `user_clubs_ibfk_2` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;

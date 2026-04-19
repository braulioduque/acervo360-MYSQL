-- MySQL dump 10.13  Distrib 8.0.19, for Win64 (x86_64)
--
-- Host: localhost    Database: acervo360_db
-- ------------------------------------------------------
-- Server version	9.0.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `clubs`
--

DROP TABLE IF EXISTS `clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clubs` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clubs`
--

LOCK TABLES `clubs` WRITE;
/*!40000 ALTER TABLE `clubs` DISABLE KEYS */;
INSERT INTO `clubs` VALUES ('04b7daec-2614-4cb4-9076-358c74b72527','5587f956-a281-48d5-8b01-21e0fa2944af','CONFEDERAÇÃO BRASILEIRA DE TIRO PRÁTICO','cadastro@cbtp.org.br','38895892000192',NULL,'RUA CASTIGLIANO','57','SALA 202','PADRE EUSTÁQUIO','Belo Horizonte','MG',NULL,'(31) 3347-4538','A','2026-04-03 23:40:47','2026-04-18 14:57:02'),('0c35f797-5d71-4b5b-8288-527d9b8c702d','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO RICHTER',NULL,NULL,'717519','R. Bernardo Guimarães','584','LOJA 2','FUNCIONÁRIOS','Belo Horizonte','MG',NULL,'(31) 97107-1093','A','2026-03-15 03:38:22','2026-04-18 14:56:48'),('0e51d856-3bd3-4843-b833-d3c29c7667ea','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO HUNTERS',NULL,'39951919000104',NULL,'ROD. BR 381','3440','2º ANDAR, LETRA A','INCONFIDENTES','Contagem','MG',NULL,'(31) 99194-3233','A','2026-04-04 00:42:48','2026-04-18 14:56:38'),('122a6041-424b-4d08-acd1-b45a43c49b86','5587f956-a281-48d5-8b01-21e0fa2944af','DELTA CLUBE DE TIRO E CAÇA - PLANALTO',NULL,'44154155000158',NULL,'AV. DOUTOR CRISTIANO GUIMARÃES','1311',NULL,'PLANALTO','Belo Horizonte','MG',NULL,'(31)98307-9195','A','2026-04-03 23:49:44','2026-04-18 14:38:49'),('18cb6be6-75f6-4cec-9dfc-bffdc6742be9','5587f956-a281-48d5-8b01-21e0fa2944af','TOPSHOT CLUBE DE TIRO E CAÇA (TARGET)','cttopshot@gmail.com','40974544000179',NULL,'RUA SÃO PAULO','1781',NULL,'LOURDES','Belo Horizonte','MG',NULL,'(31) 99111-5556','A','2026-04-04 00:23:55','2026-04-18 14:58:16'),('236a972b-1543-4243-8b83-9af47888e9dd','5587f956-a281-48d5-8b01-21e0fa2944af','DELTA CLUBE DE TIRO - VENDA NOVA','delta.recepcao01@gmail.com','33090370000116',NULL,'AV ELIAS ANTONIO ISSA','321','LOJA D','CANDELARIA','Belo Horizonte','MG',NULL,'(31)98400-4310','A','2026-04-03 23:47:34','2026-04-18 13:59:40'),('27a8cf94-6bbf-432f-b09e-935611567d09','5587f956-a281-48d5-8b01-21e0fa2944af','ATTACK CLUBE DE TIRO E CAÇA',NULL,'25213974000184','134035','Rua Rocha lagoa','260',NULL,'Cachoeirinha','Contagem','MG',NULL,'(31)3424-6929','A','2026-03-10 22:04:55','2026-04-18 14:56:08'),('2bd2c295-6e28-4d45-82de-a2d77ea7a276','5587f956-a281-48d5-8b01-21e0fa2944af','RANCHO VELHO Clube de Tiro e Caça',NULL,NULL,'374802','Faz Granja Glória','S/N',NULL,'Fazendinha','Itaúna','MG',NULL,NULL,'A','2026-03-15 03:26:01','2026-04-18 14:57:51'),('331d2929-ccfb-4bce-9341-89342732d956','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO DO SINPRF/MG','sinprf@sinprfmg.org.br','11744061000180',NULL,'RUA CHRISTINA MARIA ASSIS','21','SALA 04','CALIFORNIA','Belo Horizonte','MG',NULL,'(31)99885-8302','A','2026-04-03 23:32:13','2026-04-18 14:56:36'),('38a3aaed-b361-4316-9df9-66713bc356e1','5587f956-a281-48d5-8b01-21e0fa2944af','CETTAS CENTER FOR TACTICAL TRAINING AND SECURITY',NULL,'09052350000176',NULL,'RUA DAS CANÁRIAS','511',NULL,'SANTA AMÉLIA','Belo Horizonte','MG',NULL,'(31)99811-7431','A','2026-04-03 23:24:01','2026-04-18 14:56:20'),('3c54ba0f-04ca-4230-b0b7-e2c7c0dfba97','5587f956-a281-48d5-8b01-21e0fa2944af','PIUMA SHOOTING CLUB LTDA',NULL,NULL,'824190','RUA MARIA DE FATIMA MARCIANO MARINHO','S/N','(ESTANDE DE TIRO NESTE LOCAL), SANTA RITA (-20.821417, -40.713667), Piúma, 29.285-000','Area Rural','Piúma','ES',NULL,'(28)99904 -4400','A','2026-03-14 03:38:34','2026-04-18 14:57:48'),('5acb9196-eae7-4e6d-bf34-b8bf416d3c4a','5587f956-a281-48d5-8b01-21e0fa2944af','A FIRMA CLUBE DE TIRO E CAÇA','','43.254.106/0001-24','','RUA GUAIANA','108','','DOM BOSCO','Belo Horizonte','MG',NULL,'(31) 35643-838','A','2026-04-03 21:34:12','2026-04-18 14:52:47'),('5afc0c9f-9fe1-42b5-b0ad-e406925a49a8','5587f956-a281-48d5-8b01-21e0fa2944af','THE SHOOTER TACTICAL TRAINING BH',NULL,'42602421000132',NULL,'RUA FREI ORLANDO','647',NULL,'CAIÇARAS','Belo Horizonte','MG',NULL,'(31) 99158-8203','A','2026-04-04 00:28:06','2026-04-18 14:57:57'),('5db548f1-acd7-4998-a831-e16a0450d916','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO ARTEFATOS',NULL,'32440235000190',NULL,'RUA DOM JOSÉ PEREIRA LARA','256','LOJA A','CORAÇÃO EUCARÍSTICO','Belo Horizonte','MG',NULL,'(31)99140-0490','A','2026-04-03 23:26:51','2026-04-18 14:56:26'),('62ff5246-184a-4982-acfa-a6331185691c','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO CONTAGEM','adm.clubedetirocontagem@gmail.com','34712569000100',NULL,'AV JOSÉ FARIA DA ROCHA','782','1º e 2º ANDAR','ELDORADO','Contagem','MG',NULL,'(31) 99221-1314','A','2026-04-04 00:47:36','2026-04-18 14:38:29'),('66024e4a-ce1e-4aea-a25a-30519c1839c5','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE CENTRO DE TREINAMENTO RIACHUELO',NULL,NULL,'331028','FAZENDA RIACHUELO, ESTACAO TUPI','S/N',NULL,'ZONA RURAL','Guarani','MG',NULL,'(32)99977-2019','A','2026-03-15 03:12:09','2026-04-18 14:56:24'),('6e58f591-582c-4b35-a242-580ab46110c2','5587f956-a281-48d5-8b01-21e0fa2944af','ESPORTIRO CLUBE DE TIRO E CAÇA','vidatatica@hotmail.com','42497862000111',NULL,'RUA JACUMA','290','LOJA 02','NOVO ELDORADO','Contagem','MG',NULL,'(31) 99365-5708','A','2026-04-04 00:50:32','2026-04-18 14:57:13'),('71a05b05-1ead-494b-8357-b1542e144ac5','5587f956-a281-48d5-8b01-21e0fa2944af','MAJALUWÁ CLUBE MINEIRO DE TIRO','','26826039000100','','AV. AMAZONAS','491','18º ANDAR Sala 1801','CENTRO','Belo Horizonte','MG',NULL,'(31)98711-2046','A','2026-04-03 23:43:32','2026-04-18 14:57:36'),('7b1cc256-da0a-49ba-aacb-1f852adc3522','5587f956-a281-48d5-8b01-21e0fa2944af','TIRO RÁPIDO CLUBE DE TIRO','contato@tirorapido,com.br','35818195000166',NULL,'RUA PROF. JOSÉ VIEIRA DE MENDONÇA','271',NULL,'ENGENHO NOGUEIRA','Belo Horizonte','MG',NULL,'(31) 99143-4079','A','2026-04-04 00:34:38','2026-04-18 14:57:59'),('809b9fe3-5c0e-475a-928e-0d13fe0efc56','5587f956-a281-48d5-8b01-21e0fa2944af','TIRO RÁPIDO CLUBE DE TIRO - ESTORIL',NULL,'44488043000133',NULL,'AV. PROFESSOR MÁRIO WERNECK','654',NULL,'ESTORIL','Belo Horizonte','MG',NULL,'(31) 36546-904','A','2026-04-04 00:31:22','2026-04-18 14:58:05'),('8de9b15b-a908-4b9b-a49c-ee48e2091d7d','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO JUIZ FORANO','','','','RUA DUQUE DE CAIXIAS','200','','POÇO RICO','Juiz de Fora','MG',NULL,'(32) 32118-055','A','2026-04-08 22:54:36','2026-04-18 14:56:46'),('9126ac51-1656-4a3e-b839-61fa07ea753d','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE E ESCOLA DE TIRO ARTILHARIA','adm.artilharia@gmail.com','40100559000108',NULL,'AVENIDA VILARINHO','2830',NULL,'CENÁCULO','Belo Horizonte','MG',NULL,'(31)3243-6590','A','2026-04-03 23:35:10','2026-04-18 14:56:54'),('99bdc535-472c-456a-84d9-732698fcdc30','5587f956-a281-48d5-8b01-21e0fa2944af','PROTECT CLUBE MINEIRO DE TIRO',NULL,'01244200000152',NULL,'RUA GENERAL ANDRADE NEVES','622',NULL,'GUTIERREZ','Belo Horizonte','MG',NULL,'(31) 99211-8500','A','2026-04-04 00:15:27','2026-04-18 14:41:45'),('9cf50f87-a07a-4068-863a-ed109b2b6b80','5587f956-a281-48d5-8b01-21e0fa2944af','FEDERAÇÃO MINEIRA DE TIRO ESPORTIVO','fmgte@fmgte.org.br','18213298000183',NULL,'AV. AMAZONAS','115','SALA908','CENTRO','Belo Horizonte','MG',NULL,'(31)9265-0300','A','2026-04-03 23:57:43','2026-04-18 14:57:20'),('9da18a08-b34a-4b4e-b69f-aef7fdab0eb4','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO CAÇA E PESCA DE JUIZ DE FORA',NULL,NULL,NULL,'RODOVIA BR 040, KM 808,','S/N',NULL,'Zona Rural','Matias Barbosa','MG',NULL,'(32) 99982-0805','A','2026-03-15 03:30:35','2026-04-18 14:56:33'),('a0532fe0-df2a-4199-9c9b-a0098c98ef79','5587f956-a281-48d5-8b01-21e0fa2944af','ASGARD CLUBE DE TIRO E CAÇA',NULL,NULL,'567815','Rod. Fernão Dias, BR 381','6.519',NULL,'ÁREA RURAL','Igarapé','MG',NULL,'(31) 99867-2040','A','2026-03-15 02:56:55','2026-04-18 14:56:04'),('a2129342-522a-4c8f-be1f-4a19df44be60','5587f956-a281-48d5-8b01-21e0fa2944af','COMANDOS CLUBE DE TIRO','comandosclubedetiro@gmail.com','29082751000186',NULL,'AV. DOS ANDRADAS','107','SL J','CENTRO','Belo Horizonte','MG',NULL,'(31)99285-2527','A','2026-04-03 23:37:29','2026-04-18 14:56:56'),('abfd329a-f46d-405b-9d63-c4d666c73a40','5587f956-a281-48d5-8b01-21e0fa2944af','BRAVUS CLUBE DE TIRO','paulinhoribeiro86@hotmail.com','38442003000158',NULL,'RUA BOGARI','100',NULL,'NOVA SUISSA','Belo Horizonte','MG',NULL,'(31)98849-6165','A','2026-04-03 23:18:57','2026-04-18 14:56:12'),('ac669675-998b-4f87-9239-69a5580167ce','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO BH',NULL,'32325903000139','283500','Cesário Alvim','1100','Cep 30720-270','Padre Eustáquio','Belo Horizonte','MG',NULL,'(31)98244-8962','A','2026-03-19 02:49:12','2026-04-19 05:00:47'),('b013e846-54ac-486c-b157-b6f9d79aa6cd','5587f956-a281-48d5-8b01-21e0fa2944af','AL CAPONE CLUBE DE TIRO',NULL,'38388527000108',NULL,'RUA CORA CORALINA','95',NULL,'SANTA HELENA','Belo Horizonte','MG',NULL,'(31)98323-3679','A','2026-04-03 23:12:48','2026-04-18 14:55:39'),('b2915dc5-8bac-44d2-a027-879696b51968','5587f956-a281-48d5-8b01-21e0fa2944af','C.T.A.F ASSOCIAÇÃO DESPORTIVA DE TIRO',NULL,NULL,'290536','RODOVIA MG 844, KM 9,','S/N','SÍTIO SÃO JOSÉ,','ZONA RURAL','Queluzito','MG',NULL,NULL,'A','2026-03-15 03:04:44','2026-04-18 14:56:16'),('b5f8db50-de60-4aec-bc66-cfca911a31c1','5587f956-a281-48d5-8b01-21e0fa2944af','TIRO URBANO CLUBE DE TIRO','atendimentotu@gmail.com','09468272000195',NULL,'RUA MARÍLIA DE DIRCEU','123',NULL,'LOURDES','Belo Horizonte','MG',NULL,'(31) 71125-376','A','2026-04-04 00:37:04','2026-04-18 14:58:13'),('b9aabb2c-9f70-4b43-98fd-a4601bb131f8','5587f956-a281-48d5-8b01-21e0fa2944af','GUERRA CLUBE DE TIRO','','43554343000100','856176','RUA ITAPETINGA','64','','CANADÁ','Belo Horizonte','MG',NULL,'(31)3665-6245','A','2026-04-03 23:20:34','2026-04-18 14:57:28'),('c234b220-059d-404e-b901-d99b2301e327','5587f956-a281-48d5-8b01-21e0fa2944af','CLUBE DE TIRO ITAUNA (CTI)',NULL,NULL,NULL,'Rua Camilote','99999','CH, S/N','SUMIDOURO','Itaúna','MG',NULL,'(37) 99828-4503','A','2026-04-06 17:37:56','2026-04-18 14:56:43'),('c9537fc8-b91a-432d-aeb1-ff01b24baf1b','5587f956-a281-48d5-8b01-21e0fa2944af','MASTER CLUBE DE TIRO E CAÇA',NULL,'38032621000120',NULL,'AV. JOSÉ FARIA DA ROCHA','1028','3º ANDAR','ELDORADO','Contagem','MG',NULL,'(31) 99926-5056','A','2026-04-04 00:53:35','2026-04-18 14:57:42'),('e11426c3-1d6a-4e10-84a7-c5a514d2358c','5587f956-a281-48d5-8b01-21e0fa2944af','FEDERAÇÃO MINEIRA DE TIRO PRÁTICO','diretoria@fmtp.org.br','65162232000191',NULL,'AV. PROFESSOR MARIO WENECK','2275','SALA 104','BURITIS','Belo Horizonte','MG',NULL,'(31)98412-9228','A','2026-04-04 00:00:21','2026-04-18 14:57:26'),('e4fc393f-a781-4a05-900f-f05bf92753d0','5587f956-a281-48d5-8b01-21e0fa2944af','CT REVINT',NULL,NULL,NULL,'AV. JOSE FARIA DA ROCHA','782',NULL,'ELDORADO','Contagem','MG',NULL,NULL,'A','2026-03-15 03:33:38','2026-04-18 14:57:08'),('e8036db9-839f-4b96-8c24-8de769c632d4','5587f956-a281-48d5-8b01-21e0fa2944af','AQUILA CLUBE DE TIRO PRATICO','','04711798000130','1141','Av prof Mário Werneck','2275','','Buritis','Belo Horizonte','MG',NULL,'(31)3377-3100','A','2026-03-15 02:44:59','2026-04-18 14:55:59'),('fc58cc85-8e82-4247-b566-84caf9042501','5587f956-a281-48d5-8b01-21e0fa2944af','PROTECT CLUBE DE TIRO',NULL,'01244200000314',NULL,'AV. RAJA GABAGLIA','3950','LOJA 16A','ESTORIL','Belo Horizonte','MG',NULL,'(31) 99413-3513','A','2026-04-04 00:18:51','2026-04-18 14:42:03');
/*!40000 ALTER TABLE `clubs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `firearms`
--

DROP TABLE IF EXISTS `firearms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `firearms` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `brand` varchar(100) DEFAULT NULL,
  `model` varchar(100) DEFAULT NULL,
  `caliber` varchar(50) DEFAULT NULL,
  `serial_number` varchar(100) DEFAULT NULL,
  `acquisition_date` date DEFAULT NULL,
  `status` varchar(20) DEFAULT 'ativo',
  `firearm_type` varchar(50) DEFAULT NULL,
  `registry_type` varchar(50) DEFAULT NULL,
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firearms`
--

LOCK TABLES `firearms` WRITE;
/*!40000 ALTER TABLE `firearms` DISABLE KEYS */;
INSERT INTO `firearms` VALUES ('0aa121f0-b541-48eb-9c14-290a674d6052','daf97254-bb7d-4f58-b511-60d1b9c00c66','CBC','7022 Way','.22 LF',NULL,NULL,'ativo',NULL,NULL,NULL,'WER7689078','2026-07-27',NULL,NULL,'2026-04-05 13:42:32','2026-04-19 03:10:56'),('8264b23d-fea1-4de2-b1fb-91c76a7db023','5587f956-a281-48d5-8b01-21e0fa2944af','Taurus','G3 TORO','9mm','123','2026-04-18','ativo','Pistola','SIGMA',NULL,'2103534','2026-07-21',NULL,NULL,'2026-03-14 01:42:21','2026-04-18 14:36:34'),('8a0a8c25-3147-4176-afac-47ecacf14813','5587f956-a281-48d5-8b01-21e0fa2944af','Taurus','TS9','9mm','123','2026-04-18','ativo','Espingarda','SIGMA',NULL,'2334386','2026-07-21',NULL,NULL,'2026-03-11 00:44:09','2026-04-18 14:59:39'),('a466f911-15a8-4b8c-aef3-a529ac538e76','5587f956-a281-48d5-8b01-21e0fa2944af','CBC','7022 WAY','22 LR','234','2026-04-18','ativo','Carabina/Fuzil','SIGMA',NULL,'1853508','2026-07-21',NULL,NULL,'2026-03-14 01:32:43','2026-04-18 15:16:42'),('dcc3f5c6-8a45-4fdd-a141-9b535f3acc23','5587f956-a281-48d5-8b01-21e0fa2944af','Taurus','G2C','9mm','123','2026-04-18','ativo','Pistola','SIGMA',NULL,'1545882','2026-07-21',NULL,NULL,'2026-03-11 13:37:09','2026-04-18 14:59:18');
/*!40000 ALTER TABLE `firearms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gtes`
--

DROP TABLE IF EXISTS `gtes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gtes` (
  `id` varchar(36) NOT NULL,
  `owner_user_id` varchar(36) NOT NULL,
  `firearm_id` varchar(36) NOT NULL,
  `profile_address_id` varchar(36) NOT NULL,
  `destination_club_id` varchar(36) NOT NULL,
  `protocol_number` varchar(50) DEFAULT NULL,
  `issued_at` date DEFAULT NULL,
  `expires_at` date DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `notes` text,
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gtes`
--

LOCK TABLES `gtes` WRITE;
/*!40000 ALTER TABLE `gtes` DISABLE KEYS */;
INSERT INTO `gtes` VALUES ('269f4dfe-21c6-4251-99ed-6fcfdd5d5541','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','27a8cf94-6bbf-432f-b09e-935611567d09',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-15 02:31:20','2026-04-18 15:11:45'),('2fb454f9-6468-468e-a0ac-578ff7ee2ec2','5587f956-a281-48d5-8b01-21e0fa2944af','a466f911-15a8-4b8c-aef3-a529ac538e76','eb7623bf-23e8-4210-8d1e-94bf5972caea','a0532fe0-df2a-4199-9c9b-a0098c98ef79',NULL,'2025-06-22','2026-06-22','approved',NULL,NULL,'2026-03-15 02:59:00','2026-04-18 15:10:52'),('552214ef-bdea-4415-8e17-99be83805023','5587f956-a281-48d5-8b01-21e0fa2944af','dcc3f5c6-8a45-4fdd-a141-9b535f3acc23','eb7623bf-23e8-4210-8d1e-94bf5972caea','ac669675-998b-4f87-9239-69a5580167ce',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-15 02:40:00','2026-04-18 15:11:19'),('62337064-2d84-4238-8891-f5b9adcd1709','5587f956-a281-48d5-8b01-21e0fa2944af','8264b23d-fea1-4de2-b1fb-91c76a7db023','eb7623bf-23e8-4210-8d1e-94bf5972caea','ac669675-998b-4f87-9239-69a5580167ce',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-14 01:59:07','2026-04-18 15:12:05'),('635174e7-a1af-4846-98fc-3a1270318d8f','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','27a8cf94-6bbf-432f-b09e-935611567d09',NULL,'2026-01-07','2026-07-07','approved',NULL,NULL,'2026-03-15 02:41:39','2026-04-18 15:11:09'),('6f382fd6-1282-4b52-849a-70bbfe777a57','daf97254-bb7d-4f58-b511-60d1b9c00c66','0aa121f0-b541-48eb-9c14-290a674d6052','6e0fd23a-f2c6-485b-8d1e-1a763918d320','ac669675-998b-4f87-9239-69a5580167ce',NULL,'2026-01-02','2026-04-30','approved',NULL,NULL,'2026-04-05 13:43:51','2026-04-18 02:12:15'),('7263750a-a031-4a73-a4ea-105b189e1861','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','e4fc393f-a781-4a05-900f-f05bf92753d0',NULL,'2026-02-23','2026-08-23','approved',NULL,NULL,'2026-03-15 03:35:06','2026-04-18 15:06:14'),('8abc51a9-7761-4231-8955-30b2228ba94c','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','27a8cf94-6bbf-432f-b09e-935611567d09',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-15 03:08:33','2026-04-18 15:10:20'),('8ccd8a69-b6da-4c17-a25a-7bf0e85d6eb2','5587f956-a281-48d5-8b01-21e0fa2944af','a466f911-15a8-4b8c-aef3-a529ac538e76','eb7623bf-23e8-4210-8d1e-94bf5972caea','c234b220-059d-404e-b901-d99b2301e327',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-15 03:18:58','2026-04-18 15:06:49'),('97495c7c-52cc-4cf4-a5f7-49f88357c2cf','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','27a8cf94-6bbf-432f-b09e-935611567d09',NULL,'2025-04-19','2026-04-19','approved',NULL,NULL,'2026-03-15 03:13:44','2026-04-18 15:10:07'),('bfb0cb3a-61c6-49b2-8a7a-f4e4179ceb23','5587f956-a281-48d5-8b01-21e0fa2944af','a466f911-15a8-4b8c-aef3-a529ac538e76','eb7623bf-23e8-4210-8d1e-94bf5972caea','ac669675-998b-4f87-9239-69a5580167ce',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-14 02:04:54','2026-04-18 15:11:56'),('c8bf1904-f8c9-4480-92c3-2b791a1dbc2d','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','ac669675-998b-4f87-9239-69a5580167ce',NULL,'2025-06-04','2026-06-04','approved',NULL,NULL,'2026-03-15 03:21:10','2026-04-18 15:06:25'),('e9a7d077-1f7f-41ec-bc1e-5445814810b8','5587f956-a281-48d5-8b01-21e0fa2944af','a466f911-15a8-4b8c-aef3-a529ac538e76','eb7623bf-23e8-4210-8d1e-94bf5972caea','e8036db9-839f-4b96-8c24-8de769c632d4',NULL,'2026-02-02','2026-08-02','approved',NULL,NULL,'2026-03-15 02:53:59','2026-04-18 15:11:01'),('edde2e79-28c3-4ce5-9120-9ce34b50c9f1','5587f956-a281-48d5-8b01-21e0fa2944af','8a0a8c25-3147-4176-afac-47ecacf14813','eb7623bf-23e8-4210-8d1e-94bf5972caea','a0532fe0-df2a-4199-9c9b-a0098c98ef79',NULL,'2025-06-18','2026-06-18','approved',NULL,NULL,'2026-03-15 03:01:16','2026-04-18 15:10:33');
/*!40000 ALTER TABLE `gtes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `habitualities`
--

DROP TABLE IF EXISTS `habitualities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `habitualities` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `habitualities`
--

LOCK TABLES `habitualities` WRITE;
/*!40000 ALTER TABLE `habitualities` DISABLE KEYS */;
INSERT INTO `habitualities` VALUES ('ce214cd3-4634-44e4-84ef-787beb987e00','5587f956-a281-48d5-8b01-21e0fa2944af','Treino',NULL,'Treino',NULL,'2026-04-15','19:30:00','20:50:00','ac669675-998b-4f87-9239-69a5580167ce','CLUBE DE TIRO BH','Própria','a466f911-15a8-4b8c-aef3-a529ac538e76',NULL,NULL,NULL,NULL,NULL,'Própria',80,NULL,'147','2026-04-16 00:11:16','2026-04-18 15:12:23'),('cf03a978-0d65-42a6-b2b8-e0325871c756','5587f956-a281-48d5-8b01-21e0fa2944af','Treino',NULL,'Treino',NULL,'2026-04-15','19:30:00','20:50:00','ac669675-998b-4f87-9239-69a5580167ce','CLUBE DE TIRO BH','Própria','8a0a8c25-3147-4176-afac-47ecacf14813',NULL,NULL,NULL,NULL,NULL,'Própria',50,NULL,'147','2026-04-16 00:10:32','2026-04-18 15:12:28');
/*!40000 ALTER TABLE `habitualities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `habituality_modalities`
--

DROP TABLE IF EXISTS `habituality_modalities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `habituality_modalities` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `habituality_modalities`
--

LOCK TABLES `habituality_modalities` WRITE;
/*!40000 ALTER TABLE `habituality_modalities` DISABLE KEYS */;
INSERT INTO `habituality_modalities` VALUES ('09887439-41eb-4484-b60d-a56015a7cd55','Tiro Prático',0,'2026-04-13 16:52:21'),('212fab67-5a95-4e89-87ce-55199d7ae6b9','IPSC',0,'2026-04-13 16:52:21'),('58c367d4-67c3-4a69-a706-c0cb9cf019d0','Tiro de Precisão',0,'2026-04-13 16:52:21'),('6288830b-9d89-42ab-a55d-9e1ae895c10e','Outros',0,'2026-04-13 16:52:21'),('6979e04c-0177-4a2b-afb2-6cc3ff335cc0','IDSC',0,'2026-04-13 16:52:21'),('aa4c66c5-5185-4de0-b50e-84126527b795','Treino',0,'2026-04-13 17:30:42'),('d3b9cfd1-8221-4405-a969-38ab2e789e7b','Tiro ao Prato',0,'2026-04-13 16:52:21');
/*!40000 ALTER TABLE `habituality_modalities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `token` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `email` (`email`),
  KEY `token` (`token`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `profile_addresses`
--

DROP TABLE IF EXISTS `profile_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `profile_addresses` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `profile_addresses`
--

LOCK TABLES `profile_addresses` WRITE;
/*!40000 ALTER TABLE `profile_addresses` DISABLE KEYS */;
INSERT INTO `profile_addresses` VALUES ('5aae5502-e1f1-45ce-a89e-e0e386680e31','5587f956-a281-48d5-8b01-21e0fa2944af','primary','Rua Cubatão','361','Apto 302','Renascença','MG','Belo Horizonte','31130630','2026-04-19 01:48:12','2026-04-19 01:48:12'),('6e0fd23a-f2c6-485b-8d1e-1a763918d320','daf97254-bb7d-4f58-b511-60d1b9c00c66','primary','QRSW','03','Bloco A4','Sudoeste','DF','Brasília','70856321','2026-04-05 13:39:37','2026-04-05 13:39:37'),('82880bbc-6ab1-4930-a665-30acfc2662d5','5587f956-a281-48d5-8b01-21e0fa2944af','secondary','Rua das flores','320','apto 101','Orquideas','GO','Amaralina','63325114','2026-04-19 01:48:01','2026-04-19 01:48:01'),('af067a3d-4a83-4325-8edf-f338b629f1e8','daf97254-bb7d-4f58-b511-60d1b9c00c66','primary','QRSW','03','Bloco A4','Sudoeste','DF','Brasília','70856321','2026-04-19 14:59:09','2026-04-19 14:59:09'),('eb7623bf-23e8-4210-8d1e-94bf5972caea','5587f956-a281-48d5-8b01-21e0fa2944af','primary','Rua Cubatão','361','Apto 302','Renascença','MG','Belo Horizonte','31130630','2026-03-10 19:40:14','2026-03-13 23:17:23');
/*!40000 ALTER TABLE `profile_addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `profiles`
--

DROP TABLE IF EXISTS `profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `profiles` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `profiles`
--

LOCK TABLES `profiles` WRITE;
/*!40000 ALTER TABLE `profiles` DISABLE KEYS */;
INSERT INTO `profiles` VALUES ('5587f956-a281-48d5-8b01-21e0fa2944af','braulio.duque@gmail.com','$2b$10$qT3LfYYvnI3.WZ3WUrfme.ZNULrEZ0e1Uvb3EgOoZJb8GL2bp45QS','BRAULIO GOTTSCHALG DUQUE','78802946604','31983937447','000.545.112-40','[\"Atirador\", \"Colecionador\"]','2031-06-29','','cr-documents/1776563912613_temp_cr_1776563912574.pdf','S','2026-03-09 01:39:16','2026-04-19 20:27:22'),('91532b67-2ad8-4548-97fd-35fc0d6f1643','iat.marcotulio@gmail.com','$2b$10$zOw./BjiuJuAq6FXy6QBnOfOBInemskTAQvLZm7ZQl0U7aCYfGRZC','Marco Túlio Rodrigues',NULL,NULL,NULL,'null',NULL,NULL,NULL,'N','2026-03-19 00:27:12','2026-04-18 02:21:00'),('c1766732-d8f2-4a8c-b101-3548c1526505','jhonpedro670@gmail.com','$2b$10$zOw./BjiuJuAq6FXy6QBnOfOBInemskTAQvLZm7ZQl0U7aCYfGRZC','João Pedro R.S',NULL,NULL,NULL,'null',NULL,NULL,NULL,'N','2026-03-19 00:26:05','2026-04-18 02:21:00'),('daf97254-bb7d-4f58-b511-60d1b9c00c66','suporte@inforfile.com.br','$2b$10$BGL1Z4PXXE5Mc8NKCvFuGue1MxBYNWxKlqA.aDpGisZK/nfknBVEm','Inforfile Tecnologia',NULL,'(31) 98633-2555','000.456.987-98','[\"Colecionador\", \"Atirador\", \"Caçador\"]','2031-05-05',NULL,NULL,'N','2026-04-04 04:11:15','2026-04-19 20:28:15');
/*!40000 ALTER TABLE `profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscription_plans`
--

DROP TABLE IF EXISTS `subscription_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscription_plans` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscription_plans`
--

LOCK TABLES `subscription_plans` WRITE;
/*!40000 ALTER TABLE `subscription_plans` DISABLE KEYS */;
INSERT INTO `subscription_plans` VALUES ('042f2d9b-10ae-4c4f-b353-1f6a984a1a19','lifetime','Vitalício',999.00,'uma vez',0,NULL,NULL,0,'all_inclusive_rounded',4,1,'2026-03-20 18:37:31','2026-04-18 02:11:53'),('0c8a11f4-607c-433b-ae08-dd96a4c1be26','quarterly','Plano Trimestral',79.90,'trimestre',3,NULL,NULL,0,NULL,2,1,'2026-03-20 18:37:31','2026-04-18 02:11:53'),('6989eaa5-cfed-44ec-bbeb-49c1a5b8f5cc','monthly','Plano Mensal',29.90,'mês',1,NULL,NULL,0,NULL,3,1,'2026-03-20 18:37:31','2026-04-18 02:11:53'),('85085d92-6776-4829-9964-c86b6fa3def1','yearly','Plano Anual',299.90,'ano',12,NULL,'⭐ Mais escolhido',1,NULL,1,1,'2026-03-20 18:37:31','2026-04-18 02:11:53');
/*!40000 ALTER TABLE `subscription_plans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_clubs`
--

DROP TABLE IF EXISTS `user_clubs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_clubs` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_clubs`
--

LOCK TABLES `user_clubs` WRITE;
/*!40000 ALTER TABLE `user_clubs` DISABLE KEYS */;
INSERT INTO `user_clubs` VALUES ('112cd871-a392-49dd-af13-21af3c3b0800','5587f956-a281-48d5-8b01-21e0fa2944af','e4fc393f-a781-4a05-900f-f05bf92753d0','2026-04-03 21:40:35'),('34075253-015d-446e-aa7a-9841ba102e09','daf97254-bb7d-4f58-b511-60d1b9c00c66','ac669675-998b-4f87-9239-69a5580167ce','2026-04-05 13:43:20'),('35366ee8-477b-4bbf-ac0b-b50ca813cf8c','5587f956-a281-48d5-8b01-21e0fa2944af','27a8cf94-6bbf-432f-b09e-935611567d09','2026-04-03 23:15:59'),('35d9ccc1-64ed-4bf5-9816-55315563653f','daf97254-bb7d-4f58-b511-60d1b9c00c66','b9aabb2c-9f70-4b43-98fd-a4601bb131f8','2026-04-19 05:06:47'),('6da13051-d360-4b4b-9c07-d963bbbb5b9f','5587f956-a281-48d5-8b01-21e0fa2944af','ac669675-998b-4f87-9239-69a5580167ce','2026-04-03 20:56:31'),('7573004f-9213-41e5-9687-634c6b372b47','5587f956-a281-48d5-8b01-21e0fa2944af','a0532fe0-df2a-4199-9c9b-a0098c98ef79','2026-04-03 21:39:08'),('a10dc59e-7c26-4dc8-b212-6dda3d2e70d6','5587f956-a281-48d5-8b01-21e0fa2944af','b9aabb2c-9f70-4b43-98fd-a4601bb131f8','2026-04-17 02:21:34'),('ba03e13c-e37a-4509-8ba7-eee67e8ef33f','5587f956-a281-48d5-8b01-21e0fa2944af','e8036db9-839f-4b96-8c24-8de769c632d4','2026-04-03 21:39:46'),('d96d9316-977d-44c5-aed6-17de5b61262b','5587f956-a281-48d5-8b01-21e0fa2944af','c234b220-059d-404e-b901-d99b2301e327','2026-04-06 17:41:48');
/*!40000 ALTER TABLE `user_clubs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_subscriptions`
--

DROP TABLE IF EXISTS `user_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_subscriptions` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_subscriptions`
--

LOCK TABLES `user_subscriptions` WRITE;
/*!40000 ALTER TABLE `user_subscriptions` DISABLE KEYS */;
INSERT INTO `user_subscriptions` VALUES ('1da285a7-b7b2-4e8b-8e60-b160f79dd19e','91532b67-2ad8-4548-97fd-35fc0d6f1643','trial','2026-03-19 00:27:12','2026-04-18 00:27:12','active','2026-04-18 02:12:18','2026-04-18 02:12:18'),('a8cf2300-27ac-4866-b06c-96cdc6348ed8','daf97254-bb7d-4f58-b511-60d1b9c00c66','trial','2026-04-19 00:31:34','2026-05-19 00:31:34','active','2026-04-18 02:12:18','2026-04-19 04:38:10'),('da32a698-1723-4a2c-a3be-e3b450fbaea2','c1766732-d8f2-4a8c-b101-3548c1526505','trial','2026-03-19 00:26:05','2026-04-18 00:26:05','active','2026-04-18 02:12:18','2026-04-18 02:12:18'),('f81df641-f951-4fae-a86d-c05f6f88ca23','5587f956-a281-48d5-8b01-21e0fa2944af','lifetime','2026-03-18 20:58:19','2026-04-17 00:00:00','active','2026-04-18 02:12:18','2026-04-18 02:12:18');
/*!40000 ALTER TABLE `user_subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'acervo360_db'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-19 18:28:37

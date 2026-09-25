<CFSET Keys="serial_number_id,failure,Age">
<CFSAVECONTENT variable="SQL">
<CFOUTPUT>
DROP DATABASE IF EXISTS backblaze2;
CREATE DATABASE backblaze2;

CREATE TABLE `models` (
  `ModelID` int unsigned NOT NULL AUTO_INCREMENT,
  `Model` varchar(45) NOT NULL,
  `SchemaName` varchar(45) NOT NULL,
  `Capacity` bigint unsigned DEFAULT NULL,
  `Ignore` bit(1) DEFAULT b'0',
  `TotalDrives` int unsigned DEFAULT NULL,
  `FailedDrives` int unsigned DEFAULT '0',
  `DriveDays` int unsigned DEFAULT NULL,
  `PartitionCount` smallint unsigned DEFAULT NULL,
  `Compressed` int unsigned DEFAULT '0',
  PRIMARY KEY (`ModelID`),
  KEY `ix_Model` (`Model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `serial_numbers` (
  `SerialID` int unsigned NOT NULL AUTO_INCREMENT,
  `Dupe` bit(1) DEFAULT b'0',
  `ModelID` int unsigned NOT NULL,
  `Serial_Number` varchar(45) NOT NULL,
  `FirstDate` date DEFAULT NULL,
  `LastDate` date DEFAULT NULL,
  `Failed` bit(1) NOT NULL DEFAULT b'0',
  `PartitionID` tinyint unsigned DEFAULT NULL,
  PRIMARY KEY (`SerialID`),
  KEY `ix_ModelID` (`ModelID`),
  KEY `ix_SerialNumber` (`Serial_Number`),
  KEY `ix_LastDate` (`LastDate`),
  KEY `ix_Failed` (`Failed`),
  KEY `ix_FirstDate` (`FirstDate`),
  KEY `ix_SerialID_Dupe` (`SerialID`,`Dupe`)
) ENGINE=InnoDB AUTO_INCREMENT=125865 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE backblaze2.monthlyfailurerates (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `Year` smallint unsigned NOT NULL,
  `Month` tinyint unsigned NOT NULL,
  `ModelID` int unsigned NOT NULL,
  `TotalDrives` int unsigned NOT NULL,
  `FailedDrives` int unsigned NOT NULL,
  `FailRate` float DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UQ_Date_Model` (`Year`,`Month`,`ModelID`),
  KEY `IX_YearMonth` (`Year`,`Month`),
  KEY `IX_ModelID` (`ModelID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `smart` (
  `ID` smallint unsigned NOT NULL,
  `Name` varchar(99) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `smart` VALUES (1,'Read Error Rate'),(2,'Throughput Performance'),(3,'Spin-Up Time'),(4,'Start/Stop Count'),(5,'Reallocated Sectors Count'),(6,'Read Channel Margin'),
(7,'Seek Error Rate'),(8,'Seek Time Performance'),(9,'Power-On Hours'),(10,'Spin Retry Count'),(11,'Recalibration Retries or Calibration Retry Count'),(12,'Power Cycle Count'),
(13,'Soft Read Error Rate'),(14,'Unknown'),(15,'Media Degradation'),(16,'Unknown'),(18,'Unknown'),(20,'Unknown'),(22,'Current Helium Level'),(23,'Helium Condition Lower'),
(24,'Helium Condition Upper'),(44,'Unknown'),(46,'Unknown'),(48,'Unknown'),(52,'Unknown'),(54,'Unknown'),(56,'Unknown'),(170,'Available Reserved Space'),(171,'SSD Program Fail Count'),
(177,'Wear Range Delta'),(178,'Used Reserved Block Count'),(179,'Used Reserved Block Count Total'),(180,'Unused Reserved Block Count Total'),
(181,'Program Fail Count Total or Non-4K Aligned Access Count'),(182,'Erase Fail Count'),(183,'SATA Downshift Error Count or Runtime Bad Block'),(184,'End-to-End error / IOEDC'),
(185,'Head Stability'),(186,'Induced Op-Vibration Detection'),(187,'Reported Uncorrectable Errors'),(188,'Command Timeout'),(189,'High Fly Writes'),
(190,'Temperature Difference or Airflow Temperature'),(191,'G-sense Error Rate'),(192,'Power-off Retract Count, Emergency Retract Cycle Count (Fujitsu), or Unsafe Shutdown Count'),
(193,'Load/Unload Cycle Count '),(194,'Temperature or Temperature Celsius'),(195,'Hardware ECC Recovered'),(196,'Reallocation Event Count'),(197,'Current Pending Sector Count '),
(198,'(Offline) Uncorrectable Sector Count'),(199,'UltraDMA CRC Error Count'),(200,'Multi-Zone Error Rate'),(201,'Soft Read Error Rate or TA Counter Detected'),(207,'Spin High Current'),
(212,'Shock During Write'),(220,'Disk Shift'),(222,'Unknown'),(223,'Load/Unload Retry Count'),(224,'Unknown'),(225,'Load/Unload Cycle Count'),(226,'Load \'In\'-time'),
(228,'Power-Off Retract Cycle'),(231,'Life Left (SSDs) or Temperature'),(232,'Endurance Remaining or Available Reserved Space'),(233,'Media Wearout Indicator (SSDs) or Power-On Hours'),
(234,'Average erase count AND  Maximum Erase Count'),(235,'Good Block Count AND System(Free) Block Count'),(240,'Head Flying Hours or Transfer Error Rate (Fujitsu)'),
(241,'Total LBAs Written or Total Host Writes'),(242,'Total LBAs Read or Total Host Reads'),(243,'Total LBAs Written Expanded or Total Host Writes Expanded'),
(244,'Total LBAs Read Expanded or Total Host Reads Expanded'),(245,'Remaining Rated Write Endurancer write endurance. '),(246,'Cumulative host sectors written'),(247,'Host program page count'),
(248,'Background program page count'),(250,'Read Error Retry Rate'),(251,'Minimum Spares Remaining'),(252,'Newly Added Bad Flash Block'),(254,'Free Fall Protection'),(255,'Unknown');


CREATE TABLE `pendingload` (
  `LoadID` int unsigned NOT NULL AUTO_INCREMENT,
  `SQLFile` varchar(255) NOT NULL,
  `Processed` bit(1) DEFAULT b'0',
  `DateStamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `PartitionID` tinyint unsigned DEFAULT '0',
  PRIMARY KEY (`LoadID`),
  UNIQUE KEY `uq_sqlfile` (`SQLFile`),
  KEY `ix_processed` (`Processed`)
) ENGINE=InnoDB AUTO_INCREMENT=108284 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

</CFOUTPUT>
</CFSAVECONTENT>
<CFSET SQL=StripCR(SQL)>


<CFOUTPUT>
<pre><code>#SQL#</code></pre>
</CFOUTPUT>

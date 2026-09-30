<!---
This program checks the number of drives and current partition count of drive_stats for every database except backblaze2.
If the number of drives exceeds 1,000 per partition, add partitions to increase the number of partitions where the count
is a power of 2 until there are 1,000 drives or less per partition.
--->
<CFSET MaxDrivesPerPartition=1000>
<CFSET SQL="">

<CFQUERY name="Models" datasource="#DSN#">
	SELECT ModelID, Model, SchemaName, TotalDrives
	FROM backblaze2.Models
	WHERE `Ignore`=0
	ORDER BY SchemaName
</CFQUERY>

<CFLOOP index="CR" from="1" to="#Models.RecordCount#">
	<!--- Get number of records and partition counts --->
	<CFQUERY name="PartInfo" datasource="#DSN#">
		SELECT COUNT(DISTINCT PARTITION_NAME) AS Cnt
		FROM INFORMATION_SCHEMA.PARTITIONS
		WHERE TABLE_SCHEMA='backblaze'
		AND TABLE_NAME='#Models.SchemaName[CR]#'
	</CFQUERY>
	<CFSET CurrPartCnt=PartInfo.Cnt>
	<CFIF CurrPartCnt EQ 0>
		<CFSET CurrPartCnt=1>
	</CFIF>
	
	<CFSET CurrDrivesPerPart=Int(Val(Models.TotalDrives[CR]) / CurrPartCnt)>
	<CFIF CurrDrivesPerPart GT MaxDrivesPerPartition>
		<CFSET SetDrivesPerPart=Int(Models.TotalDrives[CR] / MaxDrivesPerPartition)>
		<CFSET PartCnt=256>
		<CFIF SetDrivesPerPart LT 2>
			<CFSET PartCnt=2>
		<CFELSEIF SetDrivesPerPart LT 4>
			<CFSET PartCnt=4>
		<CFELSEIF SetDrivesPerPart LT 8>
			<CFSET PartCnt=8>
		<CFELSEIF SetDrivesPerPart LT 16>
			<CFSET PartCnt=16>
		<CFELSEIF SetDrivesPerPart LT 32>
			<CFSET PartCnt=32>
		<CFELSEIF SetDrivesPerPart LT 64>
			<CFSET PartCnt=64>
		<CFELSEIF SetDrivesPerPart LT 128>
			<CFSET PartCnt=128>
		</CFIF>
		<CFIF PartCnt GT CurrPartCnt>
			<CFSET SQL=SQL & "-- " & Trim(NumberFormat(Models.TotalDrives[CR],"9,999")) & " drives, setting " & Int(Models.TotalDrives[CR] / PartCnt) & " per partition" & Chr(10) &
								"ALTER TABLE backblaze.#Models.SchemaName[CR]# PARTITION BY HASH(SerialID) PARTITIONS #PartCnt#;" & Chr(10) &
								"UPDATE backblaze2.serial_numbers SET PartitionID=NULL WHERE ModelID=#Models.ModelID[CR]#;" & Chr(10) & Chr(10)>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFOUTPUT>
#TS()# Done
</CFOUTPUT>

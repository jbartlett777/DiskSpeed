<!--- This program scans all of the drive tables and checks for two things:
1. If the SMART pair of columns only contain NULL values, drop it
2. If the max size of the field can be reduced from bigint, resize it to the smallest size that can still contain it unsigned
It will not resize SMART ID's 

A minimum of 100 rows is needed before null columns are dropped

Took model st4000dm000 with data through 2014-2014-12-31 from 1.87 GB to 592 MB
--->

<CFPARAM name="URL.Rescan" default="0"> <!--- Pass in any non-zero value to ignore if a table has been scanned previously and scan all tables - except for "backblaze2" which will only be scanned once due to it's size --->

<!--- SQL for creating model table schema --->
<CFFILE action="read" file="#RootDir#/CreateDriveTable.sql" variable="Schema">
<!--- Locate the SQL for creating the drive_stats table and remove everything prior 
<CFSET Loc=FindNoCase("-- DROP TABLE IF EXISTS `[Model]`.`drive_stats`;",Schema)>
<CFIF Loc GT 0>
	<CFSET Schema=Mid(Schema,Loc,Len(Schema))>
</CFIF>--->

<!--- Load in previous cache --->
<CFSET Cache=StructNew()>
<CFSET Cache.SerialID=StructNew()> <!--- Holds the last date of a drive --->
<CFSET Cache.Headers=StructNew()> <!--- Holds the Hash of the header for load ordering --->
<CFIF FileExists("#ModelDir#/Cache.json")>
	<CFFILE action="Read" file="#ModelDir#/Cache.json" variable="JSON">
	<CFIF IsJSON(JSON)>
		<CFSET Cache=DeserializeJSON(JSON)>
	<CFELSE>
		<CFOUTPUT>Bad cache.json file</CFOUTPUT>
		<CFABORT>
	</CFIF>
</CFIF>
<CFIF StructKeyExists(Cache,"Tables") EQ "NO">
	<CFSET Cache.Tables=StructNew("ordered")>
</CFIF>
<CFIF FileExists("#ModelDir#/AlterTables.sql")>
	<CFFILE action="Delete" file="#ModelDir#/AlterTables.sql">
</CFIF>

<!--- <CFSET Cache.Tables.st4000dm000.Scanned=0> --->

<CFOUTPUT>
<!DOCTYPE HTML>
<html>
<head>
<title>Backblaze File Parser</title>
<script language="JavaScript">
function S(txt) {
	document.getElementById('Status').innerHTML='-- ' + txt;
}
</script>
</head>
<body>
<div id="Status">&nbsp;</div>
</CFOUTPUT>

<CFSET PreSQL="ALTER INSTANCE DISABLE INNODB REDO_LOG;" & Chr(10)>
<CFSET PostSQL="ALTER INSTANCE ENABLE INNODB REDO_LOG;" & Chr(10)>
<CFSET PreSQL="" & Chr(10)>
<CFSET PostSQL="" & Chr(10)>
<CFSET Proc=0><!--- Counts number of alters generated --->
<CFSET StopFlag=0> <!--- Used to flag it should stop processing tables because a big one has been reached --->
<CFSET MaxSecs=60> <!--- Used to indicate if StopFlag should be set --->
<CFSET SQLGenerated=0> <!--- If still zero when a stop condition is reached, keep going --->
<CFSET MaxNumberOfAlters=20> <!--- Max number of alters to run in one batch --->
<CFSET RecreateInsteadOfDropRC=500000> <!--- If the number of records is at least this count, recreate the table and bulk load the data back in --->
<CFSET RecreateInsteadOfDropRC=999999999999> <!--- If the number of records is at least this count, recreate the table and bulk load the data back in --->

<CFQUERY name="Databases" datasource="#DSN#">
	SELECT SchemaName
	FROM backblaze2.Models
	WHERE `Ignore`=0
	  AND Compressed=1
	ORDER BY SchemaName
</CFQUERY>

<CFLOOP index="CR" from="1" to="#Databases.RecordCount#">
	<CFIF StructKeyExists(Cache.Tables,Databases.SchemaName[CR]) EQ "NO">
		<CFSET Cache.Tables[Databases.SchemaName[CR]]=StructNew()>
	</CFIF>
	<CFSET SQL="">
	<CFTRY>
		<CFQUERY name="Columns" datasource="#DSN#">
			show columns from backblaze.#Databases.SchemaName[CR]#
		</CFQUERY>
		<CFCATCH Type="Any">
			<!--- Model doesn't exist, likely from puring data & tables but leaving the model/serial number tables intact, so skip this model --->
			<CFCONTINUE>
		</CFCATCH>
	</CFTRY>
	<CFSET SQL2="">
	<CFSET Flag=0>
	<CFLOOP index="c" from="1" to="#Columns.RecordCount#">
		<CFIF ListFind("N_,R_",Left(Columns.Field[c],2))>
			<CFSET SQL2=ListAppend(SQL2,"MAX(CASE WHEN #Columns.Field[c]# IS NOT NULL THEN #Columns.Field[c]# ELSE -1 END) AS #Columns.Field[c]#","|")>
		</CFIF>
	</CFLOOP>
	<CFSET SQL=SQL & "SELECT " & Chr(10) & Replace(SQL2,"|",",#Chr(10)#","All") & Chr(10) & "FROM backblaze.#Databases.SchemaName[CR]#;">
	<CFOUTPUT><script>S('Scanning backblaze.#Databases.SchemaName[CR]#');</script></CFOUTPUT><CFFLUSH>
	<!--- Get row count --->
	<CFQUERY name="Rows" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
		SELECT COUNT(1) as Cnt FROM backblaze.#Databases.SchemaName[CR]#
	</CFQUERY>
	<!--- Require a minimum of 500 rows in order to scan --->
	<CFIF Rows.Cnt LT 500>
		<CFCONTINUE>
	</CFIF>
	<CFSET RC=Trim(NumberFormat(Rows.Cnt,"9,999"))>
	<CFOUTPUT><script>S('Scanning backblaze.#Databases.SchemaName[CR]# (#RC# rows)');</script></CFOUTPUT><CFFLUSH>
	<!--- Time this query, if it takes more than 1 minute, stop processing after it --->
	<CFSET StartTick=GetTickCount()>
	<CFQUERY name="Info" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,1,0,0)#">#SQL#</CFQUERY>
	<CFSET ExecSec=Int((GetTickCount() - StartTick) / 1000)>
	<CFIF ExecSec GTE MaxSecs>
		<CFSET StopFlag=ExecSec>
	</CFIF>
	<CFLOOP index="c" from="1" to="#Columns.RecordCount#">
		<CFIF ListFind("N,R",ListFirst(Columns.Field[c],"_"))>
			<CFIF Info[Columns.Field[c]][1] EQ -1>
				<CFSET Cache.Tables[Databases.SchemaName[CR]][Columns.Field[c]]="null">
			<CFELSEIF Info[Columns.Field[c]][1] LTE 255>
				<CFSET Cache.Tables[Databases.SchemaName[CR]][Columns.Field[c]]="tinyint">
			<CFELSEIF Info[Columns.Field[c]][1] LTE 65535>
				<CFSET Cache.Tables[Databases.SchemaName[CR]][Columns.Field[c]]="smallint">
			<CFELSEIF Info[Columns.Field[c]][1] LTE 4294967295>
				<CFSET Cache.Tables[Databases.SchemaName[CR]][Columns.Field[c]]="int">
			<CFELSE>
				<CFSET Cache.Tables[Databases.SchemaName[CR]][Columns.Field[c]]="bigint">
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFSET Drop="">
	<CFSET Alter="">
	<CFSET SQL="">
	<CFSET Pairs=StructNew("ordered")> <!--- Used to hold if 1 or 2 smart pairs were found, only drop matched pairs --->
	<CFLOOP index="Key" list="#StructKeyList(Cache.Tables[Databases.SchemaName[CR]])#">
		<CFIF ListFind("N_,R_",Left(Key,2))>
			<CFSET SMARTID=ListLast(Key,"_")>
			<CFIF StructKeyExists(Pairs,SMARTID) EQ "NO">
				<CFSET Pairs[SMARTID]=StructNew()>
				<CFSET Pairs[SMARTID].A=0> <!--- Indicates if all nulls --->
				<CFSET Pairs[SMARTID].B=""> <!--- Holds pairs of smart attributes --->
			</CFIF>
			<CFIF StructKeyExists(Cache.Tables[Databases.SchemaName[CR]],Key)>
				<CFQUERY name="CurrField" dbtype="Query">
					SELECT Type FROM Columns WHERE Field=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Key#">
				</CFQUERY>
				<CFIF CurrField.RecordCount GT 0>
					<CFSET NewType=ListFirst(CurrField.Type," ")>
					<CFIF Cache.Tables[Databases.SchemaName[CR]][Key] EQ "null">
						<CFSET Pairs[SMARTID].A=Pairs[SMARTID].A + 1>
					<CFELSEIF Cache.Tables[Databases.SchemaName[CR]][Key] NEQ NewType>
						<CFSET Pairs[SMARTID].B=ListAppend(Pairs[SMARTID].B,Key)>>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>

	<CFLOOP index="Key" list="#StructKeyList(Pairs)#">
		<CFSET Key2=Replace(RJustify(Key,3)," ","0","All")>
		<CFIF Pairs[Key].A EQ 2>
			<CFSET Drop=ListAppend(Drop,"DROP COLUMN #Key2#_N")>
			<CFSET Drop=ListAppend(Drop,"DROP COLUMN #Key2#_R")>
		</CFIF>
		<CFIF Pairs[Key].B NEQ "">
			<CFLOOP index="CurrField" list="#Pairs[Key].B#">
				<CFSET CurrField2=Replace(RJustify(ListLast(CurrField,"_"),3)," ","0","All") & "_" & ListFirst(CurrField,"_")>
				<CFIF ListFind("241,242",Key) EQ 0> <!--- Don't change total LBA written/read --->
					<CFSET Alter=ListAppend(Alter,"CHANGE COLUMN #CurrField2# #CurrField2# #Cache.Tables[Databases.SchemaName[CR]][CurrField]# UNSIGNED NULL DEFAULT NULL")>
				</CFIF>
			</CFLOOP>
		</CFIF>
	</CFLOOP>
	<!--- Sort and remove leading zeros --->
	<CFSET Drop=ListSort(Drop,"textnocase")>
	<CFSET Alter=ListSort(Alter,"textnocase")>
	<CFSET Drop=REReplace(Drop,"(\d+)_(N|R)","\2_\1","All")>
	<CFSET Drop=REReplace(Drop,"(N_|R_)0+","\1","All")>
	<CFSET Alter=REReplace(Alter,"(\d+)_(N|R)","\2_\1","All")>
	<CFSET Alter=REReplace(Alter,"(N_|R_)0+","\1","All")>
	
	<CFIF Drop NEQ "" OR Alter NEQ "">
		<CFIF Rows.Cnt LT RecreateInsteadOfDropRC OR Databases.SchemaName[CR] EQ "backblaze2">
			<CFIF ListLen(Alter) GT 0>
				<CFSET Tmp=ListAppend(Drop,Alter)>
			<CFELSE>
				<CFSET tmp=Drop>
			</CFIF>
			<CFSET SQL="-- #RC# rows" & Chr(10) & "ALTER TABLE backblaze.#Databases.SchemaName[CR]# " & Chr(10) & Replace(Tmp,",",",#Chr(10)#","All") & ";" & Chr(10)>
			<CFIF FileExists("#ModelDir#/AlterTables.sql") EQ "NO">
				<CFFILE action="Append" file="#ModelDir#/AlterTables.sql" mode="666" output="#PreSQL#">
			</CFIF>
		<CFELSE>
			<CFSET StopFlag=1>
			<CFSET SQL="-- #RC# rows, dropping table in favor of bulk loading" & Chr(10) & Chr(10) & Schema>
			<CFSET SQL=Replace(SQL,"-- DROP TABLE IF EXISTS `[Model]`.`drive_stats`;","DROP TABLE IF EXISTS `[Model]`.`drive_stats`;")>
			<CFLOOP index="CurrKey" from="1" to="255">
				<CFIF StructKeyExists(Cache.Tables[Databases.SchemaName[CR]],"smart_#CurrKey#_normalized")>
					<CFIF Cache.Tables[Databases.SchemaName[CR]]["smart_#CurrKey#_normalized"] NEQ "null">
						<CFSET SQL=Replace(SQL,"xxxx","N_#CurrKey#_ " & Cache.Tables[Databases.SchemaName[CR]]["N_#CurrKey#"] & " UNSIGNED DEFAULT NULL,")>
						<CFSET SQL=Replace(SQL,"xxxx","R_#CurrKey# " & Cache.Tables[Databases.SchemaName[CR]]["R_#CurrKey#"] & " UNSIGNED DEFAULT NULL,")>
					</CFIF>
				</CFIF>
			</CFLOOP>
			<CFSET SQL=Replace(SQL,"xxxx" & Chr(10),"","All")> <!--- Remove unused placehodlers --->
			<CFSET SQL=Replace(SQL,"[Model]",Databases.SchemaName[CR],"All")>
			<!--- Add Bulk Load statements for all CSV files for model --->
<!--- TODO: Update this
			<CFDIRECTORY action="list" directory="#ModelDir#/#Databases.SchemaName[CR]#" filter="*.csv" name="csv" sort="name asc">
			<CFIF csv.RecordCount GT 0>
				<CFSET SQL=SQL & "SET GLOBAL local_infile = 1;" & Chr(10) & Chr(10)>
				<CFLOOP index="c" from="1" to="#csv.RecordCount#">
					<!--- Get the header --->
					<CFSET FileObj=FileOpen("#csv.Directory[c]#/#csv.Name[c]#","read")>
					<CFSET Header=FileReadLine(FileObj)>
					<CFSET FileClose(FileObj)>
					<!--- Check the header against the new table to see if we need to exclude columns --->
					<CFSET ValidColumns="SerialID,date,failure,Age">
					<CFLOOP index="CurrColumn" list="#StructKeyList(Cache.Tables[Databases.SchemaName[CR]])#">
						<CFIF Left(CurrColumn,5) EQ "smart" AND Cache.Tables[Databases.SchemaName[CR]][CurrColumn] NEQ "null">
							<CFSET ValidColumns=ListAppend(ValidColumns,CurrColumn)>
						</CFIF>
					</CFLOOP>
					<CFLOOP index="i" from="1" to="#ListLen(Header)#">
						<CFSET CurrColumn=ListGetAt(Header,i)>
						<CFIF Left(CurrColumn,5) EQ "smart" AND ListFindNoCase(ValidColumns,ListGetAt(Header,i)) EQ 0>
							<CFSET Header=ListSetAt(Header,i,"@dummy#i#")>
						</CFIF>
					</CFLOOP>
					<CFSET BulkFN="#csv.Directory[c]#/#csv.Name[c]#">
					<CFSET BulkFN=Replace(BulkFN,"\","/","All")>
					<CFSET SQL=SQL & "LOAD DATA LOCAL INFILE '#BulkFN#'" & Chr(10) &
									"IGNORE" & Chr(10) &
									"INTO TABLE `#Databases.SchemaName[CR]#`.`drive_stats`" & Chr(10) &
									"FIELDS TERMINATED BY ','" & Chr(10) &
									"LINES TERMINATED BY '\n'" & Chr(10) &
									"IGNORE 1 LINES" & Chr(10) &
									"(#Header#);" & Chr(10) & Chr(10)>

				</CFLOOP>
			</CFIF> --->
		</CFIF>

		<CFSET SQL=SQL & Chr(10) &
						 "UPDATE backblaze2.models" & Chr(10) &
						 "SET Compressed=b'1'" & Chr(10) &
						 "WHERE SchemaName='#Databases.SchemaName[CR]#';" & Chr(10)>

		<CFFILE action="Append" file="#ModelDir#/AlterTables.sql" mode="666" output="#SQL#">
		<cfoutput><pre><code>#PreSQL##sql##POSTSQL#</code></pre></cfoutput>
		<CFSET SQLGenerated=1>
		<!--- Save cache --->
		<CFSET JSON=SerializeJSON(Cache)>
		<CFFILE action="write" file="#ModelDir#/Cache.json" output="#JSON#" addnewline="NO" mode="666">
		<CFIF CR LT Databases.RecordCount>
			<CFOUTPUT>-- *************************************************************<br></CFOUTPUT>
		</CFIF>
		<CFFLUSH>
		<CFSET Proc=Proc + 1>
		<!--- Only process x alters at a time 
		<CFIF Proc GT MaxNumberOfAlters>
			<CFOUTPUT><script>S('#MaxNumberOfAlters# Alters generated, please run the current SQL below and then reload this page.');</script></CFOUTPUT><CFFLUSH>
			<CFBREAK>
		</CFIF>--->
	</CFIF>

	<!--- Disable stop flag 
	<CFIF StopFlag GT 0 AND SQLGenerated EQ 1>
		<CFIF StopFlag EQ 1>
			<CFOUTPUT><script>S('Stop flag set due to table recreate needed');</script></CFOUTPUT><CFFLUSH>
		<CFELSE>
			<CFOUTPUT><script>S('Stop flag set, select took #StopFlag# seconds');</script></CFOUTPUT><CFFLUSH>
		</CFIF>
		<CFBREAK>
	<CFELSE>
		<CFSET StopFlag=0>
	</CFIF>
	--->
</CFLOOP>

<!--- Save cache --->
<CFSET JSON=SerializeJSON(Cache)>
<CFFILE action="write" file="#ModelDir#/Cache.json" output="#JSON#" addnewline="NO" mode="666">

<CFOUTPUT><script>S('Done');</script></CFOUTPUT><CFFLUSH>

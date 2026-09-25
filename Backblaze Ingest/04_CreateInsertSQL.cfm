<CFPARAM name="URL.IncludeOlderRecs" default="">

<!--- Identify how large of a SQL packet the database will accept --->
<CFQUERY name="MaxPacket" datasource="#DSN#">
	SHOW VARIABLES LIKE 'max_allowed_packet'
</CFQUERY>

<!--- Truncate pendingload table --->
<CFQUERY datasource="#DSN#">
	TRUNCATE TABLE backblaze2.pendingload
</CFQUERY>

<CFSET ProcessedDataFiles=ArrayNew(1)>
<CFIF FileExists("#ModelDir#/ProcessedDataFiles.json")>
	<CFFILE action="Read" file="#ModelDir#/ProcessedDataFiles.json" variable="JSON">
	<CFIF IsJSON(JSON)>
		<CFSET ProcessedDataFiles=DeserializeJSON(JSON)>
	<CFELSE>
		<CFOUTPUT>Bad ProcessedDataFiles.json file</CFOUTPUT>
		<CFABORT>
	</CFIF>
</CFIF>

<CFOUTPUT>
<!DOCTYPE HTML>
<html>
<head>
<title>Backblaze File Parser</title>
<script language="JavaScript">
function S(txt) {
	document.getElementById('Status').innerHTML=txt;
}
</script>
<style type="text/css">
body {
    font-family: "Courier New", Courier, monospace;
    font-size: 10pt;
}
</style>
</head>
<body>
Start at #TimeFormat(Now(),"HH:mm:ss")#<br>
<div id="Status">&nbsp;</div>
</CFOUTPUT>

<!--- Cache model databases in memory --->
<CFQUERY name="Models" datasource="#DSN#">
	SELECT ModelID, Model, SchemaName
	FROM backblaze2.models
	WHERE `Ignore`=0
	ORDER BY Model
</CFQUERY>

<!--- Cache serial number table in memory so we don't have to do seperate DB lookups later --->
<CFQUERY name="serial_numbers" datasource="#DSN#" blockfactor="100">
	SELECT *
	FROM backblaze2.serial_numbers
</CFQUERY>


<!--- Preprocess the loop to get a total number of files that will be done --->
<CFSET Sec="">
<CFSET LastSec="">
<CFSET AvgMS=0>
<CFSET RemovedFlag=0>

<CFLOOP index="CR" from="1" to="#Models.RecordCount#">

	<CFSET Out("Processing #Models.Model[CR]# - Finding data files")>

	<!--- Get a query object with all data files to search, will be faster than repeaditly scanning the directory tree for files which can take a second per model --->
	<CFDIRECTORY action="List" directory="#ModelDir#/Data/#Models.Model[CR]#" type="File" name="Files" filter="*.txt" sort="name asc">


	<!--- Get columns from model table --->
	<CFTRY>
		<CFQUERY name="TableColumns" datasource="#DSN#">
			SHOW COLUMNS FROM backblaze.#Models.SchemaName[CR]#
		</CFQUERY>
		<CFCATCH Type="Any">
			<!--- Model doesn't exist, likely from purning data & tables but leaving the model/serial number tables intact, so skip this model --->
			<CFCONTINUE>
		</CFCATCH>
	</CFTRY>
	<CFSET TableCols=ListToArray(ValueList(TableColumns.Field))>

	<!--- Fetch last date already loaded for drive --->
	<CFQUERY name="CheckDate" datasource="#DSN#">
		SELECT Max(LastDate) AS LastDate
		FROM backblaze2.serial_numbers
		WHERE ModelID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[CR]#">
	</CFQUERY>
	<CFSET LastDate=CreateDate(2000,1,1)>
	<CFIF IsDate(CheckDate.LastDate)>
		<CFSET LastDate=CheckDate.LastDate>
	</CFIF>

	<CFSET LastDir="">

	<CFSET Timer(Action="Start", Type="Average", Name="Files")>

	<CFLOOP index="FileIdx" from="1" to="#Files.RecordCount#">

		<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Loading")>

		<!--- Check to see if the file has been previously processed and skip if so --->
		<CFSET CurrFN=Replace(Files.Directory[FileIdx] & "/" & Files.Name[FileIdx],"\","/","All")>

		<CFIF ArrayFindNoCase(ProcessedDataFiles,CurrFN)>
			<CFCONTINUE>
		</CFIF>
		<CFSET ProcessedDataFiles[ArrayLen(ProcessedDataFiles) + 1]=CurrFN>

		<CFSET LoadedDates="">
		<CFSET Data=ArrayNew(1)>

		<CFFILE action="Read" file="#CurrFN#" variable="RawData">
		<CFSET RawData=StripCR(RawData)>
		<!--- Remove last LF, keeps a blank row from being processed --->
		<CFIF Right(RawData,1) EQ Chr(10)>
			<CFSET RawData=Left(RawData,Len(RawData) - 1)>
		</CFIF>

		<!--- Get Header --->
		<CFSET Header=ListFirst(RawData,Chr(10))>
		<CFSET RawData=ListDeleteAt(RawData,1,Chr(10))>

		<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Conversion")>

		<!--- Convert raw data to a query --->
		<CFSET Data=QueryNew(Header,"integer,date" & RepeatString(",integer",ListLen(Header)-2))>
		<CFSET DataArray=ListToArray(RawData,Chr(10),true)>
		<CFSET StructDelete(Variables,"RawData")> <!--- Let's remove big variables that are no longer needed from memory to aid garbage collection --->

		<!--- Convert each row to an array --->
		<CFLOOP index="Row" from="1" to="#ArrayLen(DataArray)#">
			<CFSET DataArray[Row]=ListToArray(DataArray[Row],",",true)>
		</CFLOOP>

		<!--- Convert array to query --->
		<CFSET QueryAddRow(Data,DataArray)>
		<CFSET StructDelete(Variables,"DataArray")>

		<!--- Remove rows before the last date in the database --->
		<CFQUERY name="tmp" dbtype="Query">
			SELECT #Header#
			FROM Data
			WHERE date > #CreateODBCDate(LastDate)#
		</CFQUERY>
		<CFSET RC1=Data.RecordCount>
		<CFSET RC2=tmp.RecordCount>
		<CFIF RC2 LT RC1 AND URL.IncludeOlderRecs EQ "">
			<CFOUTPUT>
			Rows that were prior to the most recent record in the database were removed.<br>
			<a href="?IncludeOlderRecs=N">Continue to exclude them</a>&nbsp;&nbsp;&nbsp;&nbsp;
			<a href="?IncludeOlderRecs=Y">Include records</a> (Including will force the FirstDate fields to be recalculated, only missing rows will be inserted, existing will be ignored)
			</CFOUTPUT>
			<CFABORT>
		</CFIF>
		<CFIF URL.IncludeOlderRecs EQ "Y">
			<CFSET DataArray=Data>
		<CFELSE>
			<CFSET DataArray=tmp>
		</CFIF>
		<CFSET StructDelete(Variables,"tmp")>

		<!--- If no rows left, skip to next file --->
		<CFSET RC=DataArray.RecordCount>
		<CFIF RC EQ 0>
			<CFCONTINUE>
		</CFIF>

		<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Removing empty columns")>

		<!--- Identify columns with data by looking at the last row --->
		<CFSET DataCols="1,2,3">
		<CFLOOP index="Col" from="4" to="#ListLen(Header)#">
			<CFIF DataArray[ListGetAt(Header,Col)][RC] NEQ "">
				<CFSET DataCols=ListAppend(DataCols,Col)>
			</CFIF>
		</CFLOOP>

		<!--- Remove null columns --->
		<CFSET tmpHeader="">
		<CFSET q=0>
		<CFLOOP index="Col" list="#DataCols#">
			<CFSET tmpHeader=ListAppend(tmpHeader,ListGetAt(Header,Col))>
		</CFLOOP>
		<CFSET Header=tmpHeader>
		<CFQUERY name="tmp" dbtype="Query">
			SELECT #Header#
			FROM Data
		</CFQUERY>
		<CFSET Data=tmp>
		<CFSET StructDelete(Variables,"tmp")>

		<CFSET FirstRowDate=DateFormat(Data.Date[1],"yyyy-mm-dd")>
		<CFSET LastRowDate=DateFormat(Data.Date[RC],"yyyy-mm-dd")>

		<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Generating SQL")>
		<!--- Convert the query back into an value list for the SQL --->
		<CFSET DataJSON=SerializeJSON(Data,"row")> <!--- Convert to JSON --->
		<CFSET QueryHeader=REMatch("{""COLUMNS"":\[.+?\]",DataJSON)> <!--- Use the header from the query in case they changed order --->
		<CFSET Hold=QueryHeader[1]>
		<CFSET QueryHeader=Mid(QueryHeader[1],13,Len(QueryHeader[1]) - 13)>
		<CFSET QueryHeader=Replace(QueryHeader,Chr(34),"","All")>
		<CFSET DataJSON=Mid(DataJSON,Len(Hold) + 10,Len(DataJSON))>
		<CFSET DataJSON=Left(DataJSON,Len(DataJSON) - 2)>
		<CFSET DataRows=Replace(DataJSON,Chr(34),"","All")> <!--- Remove quotes --->
		<CFSET DataRows=Replace(DataRows,"],[","),#Chr(10)#(","All")> <!--- Change array wrappers to ( ) --->
		<CFSET DataRows="(" & Mid(DataRows,2,Len(DataRows) - 2) & ")"> <!--- Replace outer brackets --->
		<CFSET DataRows=Replace(DataRows,",,",",NULL,","All")> <!--- Replace empty values with nulls --->
		<CFSET DataRows=Replace(DataRows,",,",",NULL,","All")> <!--- Takes two passes for consecutive nulls --->
		<CFSET DataRows=Replace(DataRows,"(,","(NULL,","All")> <!--- Insert first null --->
		<CFSET DataRows=Replace(DataRows,",)",",NULL)","All")> <!--- Insert last null --->
		<CFSET DataRows=REReplace(DataRows,",(20\d{2}-\d{2}-\d{2}),",",'\1',","All")> <!--- Put single quotes around the dates --->

		<!--- Generate SQL and check for missing (new) columns in the database table, don't put a ; after the last query in set --->
		<CFSET SQL="INSERT IGNORE INTO backblaze.#Models.SchemaName[CR]# (#QueryHeader#)#Chr(10)#VALUES#Chr(10)##DataRows#;" & Chr(10)>

		<CFSET Alter="">
		<CFLOOP index="CurrCol" list="#QueryHeader#">
			<CFIF Left(CurrCol,2) EQ "N_">
				<CFIF ArrayContainsNoCase(TableCols,"N_#Col#") EQ "NO">
					<CFSET CurrSmartID=ListLast(Col,"_")>
					<!--- Identify existing smart id col prior --->
					<CFLOOP index="LastSmartID" from="#CurrSmartID#" to="1" step="-1">
						<CFIF ArrayContainsNoCase(TableCols,"R_#LastSmartID#")>
							<CFBREAK>
						</CFIF>
					</CFLOOP>
					<CFIF Alter EQ "">
						<CFSET Alter="ALTER TABLE backblaze.#Models.SchemaName[cr]#" & Chr(10) &
										"ADD COLUMN N_#CurrSmartID# BIGINT UNSIGNED NULL AFTER R_#LastSmartID#," & Chr(10) &
										"ADD COLUMN R_#CurrSmartID# BIGINT UNSIGNED NULL AFTER N_#CurrSmartID#">
					<CFELSE>
						<CFSET Alter=Alter & "," & Chr(10) &
										"ADD COLUMN N_#CurrSmartID# BIGINT UNSIGNED NULL AFTER R_#LastSmartID#," & Chr(10) &
										"ADD COLUMN R_#CurrSmartID# BIGINT UNSIGNED NULL AFTER N_#CurrSmartID#">
					</CFIF>
					<!--- Add & sort new columns in the database table --->
					<CFLOOP index="c" from="4" to="#ArrayLen(TableCols)#">
						<CFIF TableCols[c] EQ "R_#LastSmartID#">
							<CFSET ArrayInsertAt(TableCols,c + 1,"R_#CurrSmartID#")>
							<CFSET ArrayInsertAt(TableCols,c + 1,"N_#CurrSmartID#")>
							<CFBREAK>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFLOOP>
		<CFIF Alter NEQ "">
			<!--- Run alter query to add new columns --->
			<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Adding new SMART columns")>
			<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(Alter)#</CFQUERY>
			<CFQUERY datasource="#DSN#">
				UPDATE backblaze2.models
				SET Compressed=0
				WHERE ModelID=#Models.ModelID[CR]#
			</CFQUERY>
			<CFSET Alter="">
			<!--- Refresh columns --->
			<CFQUERY name="TableColumns" datasource="#DSN#">
				SHOW COLUMNS FROM backblaze.#Models.SchemaName[CR]#
			</CFQUERY>
			<CFSET TableCols=ListToArray(ValueList(TableColumns.Field))>
		</CFIF>

		<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Saving SQL")>

		<!--- Save SQL and log into Pending Load table --->
		<CFSET SQLPath="#ModelDir#/SQL/#Models.Model[CR]#">
		<CFSET CreatePath(SQLPath)>
		<CFSET CreatePath(SQLPath)>
		<CFIF Len(SQL) LT MaxPacket.Value>
			<CFSET SQLInsFN=SQLPath & "/" & ListDeleteAt(Files.Name[FileIdx],ListLen(Files.Name[FileIdx],"."),".") & ".sql">
			<CFFILE action="Write" file="#SQLInsFN#" output="#SQL#" mode="666" addnewline="no">
			<CFQUERY datasource="#DSN#">
				INSERT IGNORE INTO backblaze2.pendingload (SQLFile, ModelID) VALUES
				(
					<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SQLInsFN#">,
					<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[CR]#">
				)
			</CFQUERY>
		<CFELSE>
			<!--- SQL statement is too large to send in one chunk, break it up --->
			<CFSET Out("Processing #Models.Model[CR]# (#CR#/#Models.RecordCount#) - #Files.Name[FileIdx]# (#FileIdx#/#Files.RecordCount#) - Saving large SQL into smaller blocks")>
			<CFSET ChunkIdx=0>
			<CFSET SnipSQL=1>
			<CFLOOP condition="SnipSQL EQ 1">
				<CFSET ChunkIdx=ChunkIdx + 1>
				<!--- Grab a chunk of SQL --->
				<CFSET Chunk=Left(SQL,MaxPacket.value - 1024)>
				<!--- Locate the end of the last full values set --->
				<CFLOOP index="Loc" from="#Len(Chunk)#" to="1" step="-1">
					<CFIF Mid(Chunk,Loc,1) EQ ")">
						<CFBREAK>
					</CFIF>
				</CFLOOP>
				<!--- Locate the start of the next full values set --->
				<CFLOOP index="Loc2" from="#Loc#" to="#Len(SQL)#">
					<CFIF Mid(SQL,Loc2,1) EQ "(">
						<CFBREAK>
					</CFIF>
				</CFLOOP>
				<CFSET Chunk=Left(Chunk,Loc) & ";"> <!--- Trim off the broken up values set --->
				<CFSET SQLInsFN=SQLPath & "/" & ListDeleteAt(Files.Name[FileIdx],ListLen(Files.Name[FileIdx],"."),".") & "_" & ChunkIdx & ".sql">
				<CFFILE action="Write" file="#SQLInsFN#" output="#Chunk#" mode="666" addnewline="no">
				<CFQUERY datasource="#DSN#">
					INSERT IGNORE INTO backblaze2.pendingload (SQLFile, ModelID) VALUES
					(
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SQLInsFN#">,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[CR]#">
					)
				</CFQUERY>

				<CFSET SQL=Mid(SQL,Loc2,Len(SQL))>
				<CFSET SQL="INSERT IGNORE INTO backblaze.#Models.SchemaName[CR]# (#QueryHeader#)#Chr(10)#VALUES#Chr(10)##SQL#">

				<CFIF Len(SQL) LT MaxPacket.Value>
					<CFSET SnipSQL=0>
					<CFSET ChunkIdx=ChunkIdx + 1>
					<CFSET SQLInsFN=SQLPath & "/" & ListDeleteAt(Files.Name[FileIdx],ListLen(Files.Name[FileIdx],"."),".") & "_" & ChunkIdx & ".sql">
					<CFFILE action="Write" file="#SQLInsFN#" output="#SQL#" mode="666" addnewline="no">
					<CFQUERY datasource="#DSN#">
						INSERT IGNORE INTO backblaze2.pendingload (SQLFile, ModelID) VALUES
						(
							<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SQLInsFN#">,
							<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[CR]#">
						)
					</CFQUERY>
				</CFIF>

			</CFLOOP>
		</CFIF>

		<CFSET Timer(Name="Files", Action="Lap")>

	</CFLOOP>
	<!--- Save processed files --->
	<CFSET JSON=SerializeJSON(ProcessedDataFiles)>
	<CFFILE action="write" file="#ModelDir#/ProcessedDataFiles.json" output="#JSON#" addnewline="NO" mode="666">
</CFLOOP>

<CFIF URL.IncludeOlderRecs EQ "Y">
	<CFSET SQLFN=SQLPath & "/PurgeFirstDate.sql">
	<CFFILE action="Write" file="#SQLFN#" output="UPDATE backblaze2.serial_numbers SET FirstDate=NULL" mode="666" addnewline="no">
	<CFQUERY datasource="#DSN#">
		INSERT IGNORE INTO backblaze2.pendingload (SQLFile, ModelID) VALUES
		(
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SQLFN#">,
			<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="0">
		)
	</CFQUERY>
</CFIF>

<CFOUTPUT>
Done at #TimeFormat(Now(),"HH:mm:ss")#<br>
</CFOUTPUT>

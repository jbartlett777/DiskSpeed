<!--- Identify how large of a SQL packet the database will accept --->
<CFQUERY name="MaxPacket" datasource="#DSN#">
	SHOW VARIABLES LIKE 'max_allowed_packet'
</CFQUERY>

<!--- Identify how many sets of 5k records there are to process --->
<CFQUERY name="Sets" datasource="#DSN#">
	SELECT COUNT(1) / 5000 as Batches
    FROM backblaze2.pendingload
	WHERE Processed=0
</CFQUERY>
<CFSET TotalBatches=Sets.Batches>
<CFIF TotalBatches NEQ Int(TotalBatches)>
	<CFSET TotalBatches=Int(TotalBatches) + 1>
</CFIF>

<!--- Fetch the drives grouped by known partition ID's --->
<CFQUERY name="Files" datasource="#DSN#">
	SELECT p.LoadID, p.SQLFile
	FROM backblaze2.pendingload p
    LEFT JOIN backblaze2.serial_numbers s ON s.SerialID=p.SerialID
	WHERE p.Processed=0
	LIMIT 0,5000
</CFQUERY>
<CFQUERY name="MaxID" datasource="#DSN#">
	SELECT MAX(LoadID) as LoadID
	FROM backblaze2.pendingload
</CFQUERY>

<CFOUTPUT>
<!DOCTYPE html>
<head>
<title>Load SQL</title>
</head>
<body>
<style type="text/css">
body, td {
    font-family: "Courier New", Courier, monospace;
    font-size: 10pt;
}
</style>
Start at #TimeFormat(Now(),"HH:mm:ss")#<br>
<div id="status">No files to process</div>
<script>
function o(status) {
	document.getElementById('status').innerHTML=status;
}
</script>
</CFOUTPUT>

<CFSET BatchSQL=ArrayNew(1)>
<CFSET BatchSQLLoadIDs=ArrayNew(1)>
<CFSET BatchSQLSize=0>
<CFSET BatchCheckedTables=ArrayNew(1)>
<CFSET BatchInsTables="">
<CFLOOP index="CR" from="1" to="#Files.RecordCount#">
	<CFSET Avg=Int(Files.LoadID[CR] / MaxID.LoadID / 0.01)>
	<CFSET BlockAvg=Int(CR / Files.RecordCount / 0.01)>
	<CFOUTPUT><script>o('#TS()# Batches: #TotalBatches# - #CR#/#Files.RecordCount# - #BlockAvg#%');</script>#Chr(10)#</CFOUTPUT><CFFLUSH>
	<CFFILE action="read" file="#Files.SQLFile[CR]#" variable="SQL">

	<CFLOOP index="i" from="1" to="#ListLen(SQL,";")#">
		<CFSET CurrSQL=ListGetAt(SQL,i,";")>
		<CFIF Left(CurrSQL,6) EQ "INSERT">
			<CFSET CurrTable=ListLast(ListGetAt(CurrSQL,4," "),".")>
			<CFIF ListFind(BatchInsTables,CurrTable) EQ 0>
				<CFSET BatchInsTables=ListAppend(BatchInstables,CurrTable)>
			</CFIF>
		</CFIF>

		<!--- Check to see if the current batched up SQL would exceed the database's max allowed. If so, send it now --->
		<CFIF Len(CurrSQL) GT MaxPacket.Value>
			<CFOUTPUT>The following file contains SQL that is too large to send in one block<br>#Files.SQLFile[CR]#<br></CFOUTPUT>
			<CFCONTINUE>
		</CFIF>
		<CFIF MultiSQL AND BatchSQLSize + Len(CurrSQL) GTE MaxPacket.Value>
			<!--- The next query to process exceets the max packet size of the database, flush what we've gathered so far --->
			<CFSET TotalSQL=ArrayLen(BatchSQL)>
			<CFSET S="">
			<CFIF ListLen(BatchInsTables) GT 1>
				<CFSET S="s">
			</CFIF>
			<CFSET BatchInstables=Replace(ListSort(BatchInsTables,"textnocase","asc"),",","<br>","All")>
			<CFOUTPUT><script>o('#TS()# Batches: #TotalBatches# - #CR - 1#/#Files.RecordCount# - #BlockAvg#% - Executing batch SQL (#TotalSQL#)<br><br>Model#s#:<br>#BatchInstables#');</script>#Chr(10)#</CFOUTPUT><CFFLUSH>
			<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(ArrayToList(BatchSQL,";"))#</CFQUERY>
			<!--- Mark the files as processed --->
			<CFQUERY datasource="#DSN#">
				UPDATE backblaze2.pendingload
				SET Processed=1
				WHERE LoadID IN (<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#ArrayToList(BatchSQLLoadIDs)#" list="true">)
			</CFQUERY>
			<!--- Prep for next batch --->
			<CFSET BatchInsTables="">
			<CFSET BatchSQL=ArrayNew(1)>
			<CFSET BatchSQLLoadIDs=ArrayNew(1)>
			<CFSET BatchSQLSize=0>
		</CFIF>

		<CFIF Trim(CurrSQL) NEQ "">
			<CFTRY>
				<CFIF MultiSQL>
					<CFIF Left(CurrSQL,6) EQ "INSERT">
						<!--- Local insert column list --->
						<CFSET CurrTable=ListGetAt(CurrSQL,4," ")>
						<CFIF ArrayContains(BatchCheckedTables,CurrTable) EQ "NO"> <!--- Cache the tables that have been checked for missing columns --->
							<CFSET ArrayAppend(BatchCheckedTables,CurrTable)>
							<CFSET Loc1=Find("(",CurrSQL)>
							<CFSET Loc2=Find(")",CurrSQL)>
							<CFSET ColList=Mid(CurrSQL,Loc1 + 1,Loc2 - Loc1 - 1)>
							<!--- Test if the query will run, if not, add missing columns --->
							<CFQUERY datasource="#DSN#">SELECT #ColList# FROM #CurrTable# LIMIT 0,1</CFQUERY>
						</CFIF>
					</CFIF>
					<!--- All expected columns exist, add SQL to batch --->
					<CFIF Right(CurrSQL,1) EQ ";">
						<CFSET CurrSQL=Left(CurrSQL,Len(CurrSQL) - 1)>
					</CFIF>
					<CFSET ArrayAppend(BatchSQL,CurrSQL)>
					<CFSET ArrayAppend(BatchSQLLoadIDs,Files.LoadID[CR])>
					<CFSET BatchSQLSize=BatchSQLSize + Len(CurrSQL) + 1>
				<CFELSE>
					<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(CurrSQL)#</CFQUERY>
				</CFIF>
				<CFCATCH type="Database">

					<CFIF FindNoCase("Unknown column",CFCATCH.Message) EQ 0>
						<CFRETHROW>
					</CFIF>

					<!--- Query has columns not known, add them --->
					<CFSET SchemaName=ListGetAt(SQL,4," ")>
					<CFQUERY name="TableColumns" datasource="#DSN#">
						SHOW COLUMNS FROM #SchemaName#
					</CFQUERY>
					<CFSET TableColsList=ValueList(TableColumns.Field)>
					<CFSET TableCols=ListToArray(TableColsList)>
					<CFSET Alter="">
					<CFSET InsColumns=REMatchNoCase("\(SerialID.+?\)",CurrSQL)>
					<CFIF ArrayLen(InsColumns) NEQ 1>
						<CFOUTPUT>
						Unable to determine columns from query
						SQL:<pre><code>#CurrSQL#</code></pre>
						</CFOUTPUT>
						<CFABORT>
					</CFIF>
					<CFSET InsColumns=Mid(InsColumns[1],2,Len(InsColumns[1])-2)>
					<CFLOOP index="CurrCol" list="#InsColumns#">
						<CFIF Left(CurrCol,2) EQ "N_">
							<CFSET CurrSmartID=ListLast(CurrCol,"_")>
							<CFIF ArrayContainsNoCase(TableCols,"N_#CurrSmartID#") EQ "NO">
								<!--- Identify existing smart id col prior --->
								<CFLOOP index="LastSmartID" from="#CurrSmartID#" to="1" step="-1">
									<CFIF ArrayContainsNoCase(TableCols,"R_#LastSmartID#")>
										<CFBREAK>
									</CFIF>
								</CFLOOP>
								<CFIF Alter EQ "">
									<CFSET Alter="ALTER TABLE #SchemaName#" & Chr(10) &
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
						<!--- Log Alter Statement in PendingLoad table --->
						<CFOUTPUT>#SchemaName#: Columns added<br></CFOUTPUT>
						<CFSET Out("Adding columns to #SchemaName#")>
						<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(Alter)#</CFQUERY>
						<CFQUERY datasource="#DSN#">
							UPDATE backblaze2.models
							SET Compressed=0
							WHERE SchemaName=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SchemaName#">
						</CFQUERY>
						<CFSET Alter="">
						<CFIF MultiSQL EQ 0>
							<!--- Redo insert --->
							<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(CurrSQL)#</CFQUERY>
						</CFIF>
					</CFIF>

				</CFCATCH>
			</CFTRY>
		</CFIF>
	</CFLOOP>

</CFLOOP>

<CFIF MultiSQL>
	<!--- Execute batch SQL --->
	<CFIF ArrayLen(BatchSQL) GT 0>
		<CFSET S="">
		<CFIF ListLen(BatchInsTables) GT 1>
			<CFSET S="s">
		</CFIF>
		<CFSET TotalSQL=ArrayLen(BatchSQL)>
		<CFSET BatchInstables=Replace(ListSort(BatchInsTables,"textnocase","asc"),",","<br>","All")>
		<CFOUTPUT><script>o('#TS()# Batches: #TotalBatches# - #CR - 1#/#Files.RecordCount# - #BlockAvg#% - Executing final batch SQL (#TotalSQL#)<br><br>Model#s#:<br>#BatchInstables#');</script>#Chr(10)#</CFOUTPUT><CFFLUSH>
		<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(ArrayToList(BatchSQL,";"))#</CFQUERY>
		<!--- Mark the files as processed --->
		<CFQUERY datasource="#DSN#">
			UPDATE backblaze2.pendingload
			SET Processed=1
			WHERE LoadID IN (<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#ArrayToList(BatchSQLLoadIDs)#" list="true">)
		</CFQUERY>
	</CFIF>
<CFELSE>
	<CFQUERY datasource="#DSN#">
		UPDATE backblaze2.pendingload
		SET Processed=1
		WHERE LoadID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Files.LoadID[CR]#">
	</CFQUERY>
</CFIF>


<CFOUTPUT>
Done at #TimeFormat(Now(),"HH:mm:ss")#<br>
<!--- If 5,000 objects were returned, assume there are more and reload the page --->
<CFIF Files.RecordCount EQ 5000>
	<script>
	location.reload(true);
	</script>
	<CFABORT>
</CFIF>
</CFOUTPUT>


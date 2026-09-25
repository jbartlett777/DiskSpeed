<CFSET AuditDir=SourceDir>

<!--- Get all tables in Backblaze schema --->
<CFQUERY name="Models" datasource="#DSN#">
	show tables in `backblaze`
</CFQUERY>
<!--- Build tally query --->
<CFSET SQL="">
<CFLOOP index="ModelIDx" from="1" to="#Models.RecordCount#">
	<CFIF ModelIDX NEQ 1>
		<CFSET SQL=SQL & "UNION ALL" & Chr(10)>
	</CFIF>
	<CFSET SQL=SQL & "SELECT '#Models.Tables_in_backblaze[ModelIDx]#' as T, COUNT(1) as Cnt FROM backblaze.#Models.Tables_in_backblaze[ModelIDx]# WHERE Date='[Date]'" & Chr(10)>
</CFLOOP>
<!--- Get Model table --->
<CFQUERY name="Models" datasource="#DSN#">
	SELECT Model, SchemaName
	FROM backblaze2.models
	ORDER BY Model
</CFQUERY>

<CFDIRECTORY action="list" directory="#AuditDir#" filter="*.csv" name="Files">

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
<div id="Status">Building Serial Number cache struct</div>
</CFOUTPUT>
<CFFLUSH>

<CFSET Cache=CacheDrives()>
<CFSET Abort=0>

<CFLOOP index="FileIDx" from="1" to="#Files.RecordCount#">
	<CFSET Out("#Files.Name[FileIDx]# (#FileIDx#/#Files.RecordCount#) - Counting lines")>
	<CFFILE action="Read" file="#Files.Directory[FileIDx]#/#Files.Name[FileIDx]#" variable="CSV">
	<CFSET CSV=StripCR(CSV)> <!--- Remove carriage returns --->
	<CFSET CSVHeader=ListFirst(CSV,Chr(10))>
	<CFLOOP index="i" from="1" to="255"> <!--- Shorthand headers --->
		<CFSET CSVHeader=Replace(CSVHeader,"smart_#i#_normalized","N_#i#")>
		<CFSET CSVHeader=Replace(CSVHeader,"smart_#i#_raw","R_#i#")>
	</CFLOOP>
	<CFSET CSV=ListDeleteAt(CSV,1,Chr(10))> <!--- Remove header line --->
	<CFIF Right(CSV,1) EQ Chr(10)>
		<CFSET CSV=Left(CSV,Len(CSV) - 1)> <!--- Remove trailing line feed --->
	</CFIF>
	<CFSET CSVLC=ListLen(CSV,Chr(10))> <!--- Line Count --->
	<CFSET Out("#Files.Name[FileIDx]# (#FileIDx#/#Files.RecordCount#) - Counting lines (" & NumberFormat(CSVLC,"9,999") & ") - Counting records from database")>
	<CFSET RunSQL=Replace(SQL,"[Date]",ListDeleteAt(Files.Name[FileIDx],2,"."),"All")>
	<CFQUERY name="Audit" datasource="#DSN#">#PreserveSingleQuotes(RunSQL)#</CFQUERY>
	<CFSET DBSum=ArraySum(ListToArray(ValueList(Audit.Cnt)))>
	<CFIF CSVLC NEQ DBSum>
		<CFOUTPUT>#Files.Name[FileIDx]#: Line Count [#NumberFormat(CSVLC,"9,999")#] DB Count: [#Trim(NumberFormat(DBSum,"9,999"))#]<br></CFOUTPUT>
		<CFIF DBSum EQ 0>
			<CFCONTINUE>	<!--- Report but no by serial audit, just reload the file --->
		</CFIF>
		<CFSET SerialIDsInserted="">
		<CFSET FileDate=ListDeleteAt(Files.Name[FileIDx],ListLen(Files.Name[FileIDx],"."),".")>
		<CFSET DataArray=ListToArray(CSV,Chr(10),true)>
		<!--- Convert each row to an array --->
		<CFLOOP index="Row" from="1" to="#ArrayLen(DataArray)#">
			<CFSET DataArray[Row]=ListToArray(DataArray[Row],",",true)>
		</CFLOOP>
		<CFSET Data=QueryNew(CSVHeader)>
		<CFSET QueryAddRow(Data,DataArray)> <!--- Convert to a query --->
		<!--- Loop over the models to find where the mismatch lies --->
		<CFLOOP index="ModelIDx" from="1" to="#Models.RecordCount#">
			<!--- Get all drives for model from the CSV, limited to just serial number until we need more --->
			<CFQUERY name="CSVSerials" dbtype="Query">
				SELECT serial_number
				FROM Data
				WHERE Model='#Models.Model[ModelIDx]#'
			</CFQUERY>
			<CFIF CSVSerials.RecordCount GT 0>
				<CFQUERY name="DBSerials" datasource="#DSN#" blockfactor="100">
					SELECT s.serial_number
					FROM backblaze.#Models.SchemaName[ModelIDx]# d
					INNER JOIN backblaze2.serial_numbers s ON d.SerialID=s.SerialID
					WHERE Date='#FileDate#'
				</CFQUERY>
				<CFIF CSVSerials.RecordCount NEQ DBSerials.RecordCount>
					<CFOUTPUT>&nbsp;&nbsp;&nbsp;&nbsp;#Models.Model[ModelIDx]# - CSV: #NumberFormat(CSVSerials.RecordCount,"9,999")# DB: #NumberFormat(DBSerials.RecordCount,"9,999")#</CFOUTPUT>
					<CFFLUSH>
					<!--- Find missing serial number --->
					<CFQUERY name="Missing" dbtype="Query">
						SELECT serial_number
						FROM CSVSerials
						WHERE serial_number NOT IN (SELECT serial_number FROM DBSerials)
					</CFQUERY>
					<!--- Get full record set --->
					<CFQUERY name="CSVRecords" dbtype="Query">
						SELECT *
						FROM Data
						WHERE Model='#Models.Model[ModelIDx]#'
						  AND serial_number IN ('#PreserveSingleQuotes(Replace(ValueList(Missing.serial_number),",","','","All"))#')
					</CFQUERY>
					<!--- Build reference query --->
					<CFSET Ref=QueryNew("serial_number,SerialID","varchar,varchar")>
					<CFLOOP index="i" from="1" to="#Missing.RecordCount#">
						<CFIF StructKeyExists(Cache,Models.Model[ModelIDx]) AND StructKeyExists(Cache[Models.Model[ModelIDx]],Missing.serial_number[i])>
							<CFSET QueryAddRow(Ref)>
							<CFSET QuerySetCell(Ref,"serial_number",Missing.serial_number[i])>
							<CFSET QuerySetCell(Ref,"SerialID",Val(ListLast(Cache[Models.Model[ModelIDx]][Missing.serial_number[i]].SerialID,"|")))>
						<CFELSE>
							<!--- Record not in the cache, verify it doesn't exist in the DB --->
							<CFQUERY name="IDLookup" datasource="#DSN#">
								SELECT s.SerialID
								FROM backblaze2.serial_numbers s
                                INNER JOIN backblaze2.models m ON m.ModelID=s.ModelID AND m.Model='#Models.Model[ModelIDx]#'
								WHERE s.Serial_Number='#Missing.serial_number[i]#';
							</CFQUERY>
							<CFIF IDLookup.RecordCount EQ 1>
								<!--- Record exists, add to reference query --->
								<CFSET QueryAddRow(Ref)>
								<CFSET QuerySetCell(Ref,"serial_number",Missing.serial_number[i])>
								<CFSET QuerySetCell(Ref,"SerialID",IDLookup.SerialID[1])>
							<CFELSE>
								<!--- The Serial Number doesn't exist, add it. But first, check to see if the model exists --->
								<CFIF StructKeyExists(Cache,Models.Model[ModelIDx]) EQ "NO">
									<CFOUTPUT>TODO: Not sure if this logic will ever execute, but stop if it needs to be added</CFOUTPUT>
									<CFABORT>
								</CFIF>
								<CFQUERY name="FailureFlag" dbtype="Query">
									SELECT failure
									FROM CSVRecords
									WHERE serial_number='#Missing.serial_number[i]#'
								</CFQUERY>
								<CFSET Fail=0>
								<CFIF FailureFlag.failure NEQ 0> <!--- Catch non 0/1 values --->
									<CFSET Fail=1>
								</CFIF>
								<CFQUERY result="Result" datasource="#DSN#">
									INSERT INTO backblaze2.serial_numbers (ModelID, Serial_Number, FirstDate, Failed)
									VALUES (
											<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Cache[Models.Model[ModelIDx]].ModelID#">,
											<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Serial#">,
											<cfqueryparam CFSQLType="CF_SQL_Date" value="#CreateODBCDate(FileDate)#">,
											<cfqueryparam CFSQLType="CF_SQL_BIT" value="#Fail#">
											)
								</CFQUERY>
								<CFSET SerialID=Result.GeneratedKey>
								<!--- Add to ref table --->
								<CFSET QueryAddRow(Ref)>
								<CFSET QuerySetCell(Ref,"serial_number",Missing.serial_number[i])>
								<CFSET QuerySetCell(Ref,"SerialID",IDLookup.SerialID[1])>
								<!--- Save to internal cache --->
								<CFSET Cache[Models.Model[ModelIDx]][Missing.serial_number[i]]=StructNew()>
								<CFSET Cache[Models.Model[ModelIDx]][Missing.serial_number[i]]=SerialID=SerialID>
							</CFIF>
						</CFIF>
						
					</CFLOOP>
					<!--- Get column headers and cache --->
					<CFQUERY name="TableColumns" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
						SHOW COLUMNS FROM backblaze.#Cache[Models.Model[ModelIDx]].SchemaName#
					</CFQUERY>
					<CFSET Header=ValueList(TableColumns.Field)>
					<CFSET Loc=ListFind(Header,"N_1")>
					<!--- Check to see if header cells exist in the current file --->
					<CFLOOP index="CellIDx" from="#ListLen(Header)#" to="#Loc#" step="-1">
						<CFSET Cell=ListGetAt(Header,CellIDx)>
						<CFIF Mid(Cell,2,1) EQ "_" AND ListFindNoCase(CSVHeader,Cell) EQ 0>
							<CFSET Header=ListDeleteAt(Header,CellIDx)>
						</CFIF>
					</CFLOOP>
					<!--- Duplicate CSVRecords with the included ModelID & SerialID columns --->
					<CFSET ModelID=Cache[Models.Model[ModelIDx]].ModelID>
					<CFQUERY name="CSVRecords2" dbtype="Query">
						SELECT #ModelID# as ModelID, r.SerialID, c.*
						FROM CSVRecords c
						INNER JOIN Ref r ON r.serial_number=c.serial_number
					</CFQUERY>

					<!--- Buld a list of SerialID's to clear the FirstDate value --->
					<CFLOOP index="row" from="1" to="#CSVRecords2.RecordCount#">
						<CFIF ListFind(SerialIDsInserted,CSVRecords2.SerialID[Row]) EQ 0>
							<CFSET SerialIDsInserted=ListAppend(SerialIDsInserted,CSVRecords2.SerialID[Row])>
						</CFIF>
					</CFLOOP>
					<CFIF Len(SerialIDsInserted) GT 10240>
						<!--- Occationally flush SerialIDsInserted to prevent it from getting too long --->
						<CFQUERY datasource="#DSN#">
							UPDATE backblaze2.serial_numbers SET FirstDate=NULL WHERE SerialID IN (#SerialIDsInserted#)
						</CFQUERY>
						<CFSET SerialIDsInserted="">
					</CFIF>

					<CFSET PatchSQL="INSERT INTO backblaze.#Cache[Models.Model[ModelIDx]].SchemaName# (#Header#) VALUES">
					<CFSET Rows=ArrayNew(1)>
					<CFSET RowIDx=0>
					<!--- Build Row Array --->
					<CFLOOP index="Row" from="1" to="#CSVRecords2.RecordCount#">
						<CFSET RowIDx=RowIDx + 1>
						<CFSET Rows[RowIDx]="">
						<CFLOOP index="Cell" list="#Header#">
							<CFIF Cell EQ "Date">
								<CFSET Rows[RowIDx]=ListAppend(Rows[RowIDx],"'" & DateFormat(CSVRecords2[Cell][Row],"yyyy-mm-dd") & "'",",",true)>
							<CFELSEIF Cell EQ "Age">
								<CFSET Rows[RowIDx]=ListAppend(Rows[RowIDx],"NULL",",",true)>
							<CFELSE>
								<CFSET Rows[RowIDx]=ListAppend(Rows[RowIDx],CSVRecords2[Cell][Row],",",true)>
							</CFIF>
						</CFLOOP>
						<CFSET Rows[RowIDx]=Replace(Rows[RowIDx],",,",",NULL,","All")>
						<CFSET Rows[RowIDx]=Replace(Rows[RowIDx],",,",",NULL,","All")>
						<CFIF Right(Rows[RowIDx],1) EQ ",">
							<CFSET Rows[RowIDx]=Rows[RowIDx] & "NULL">
						</CFIF>
						<CFSET Rows[RowIDx]="(" & Rows[RowIDx] & ")">
						<CFIF ArrayLen(Rows) GTE 10000>
							<!--- Large record set, flush --->
							<CFOUTPUT> Inserting data (#Trim(NumberFormat(ArrayLen(Rows),"9,999"))#)</CFOUTPUT><CFFLUSH>
							<CFTRY>
								<CFQUERY datasource="#DSN#">#PatchSQL# #PreserveSingleQuotes(ArrayToList(Rows))#</CFQUERY>
								<CFCATCH Type="Database">
									<CFSET Msg=CFCATCH.Message>
									<CFIF Left(Msg,46) EQ "Data truncation: Out of range value for column">
										<CFSET Loc1=Find(" at row",Msg)>
										<CFIF Loc1 GT 0>
											<CFSET Msg=Left(Msg,Loc1 - 1)>
										</CFIF>
										<CFSET Loc1=Find("'",Msg)>
										<CFSET Loc2=Find("'",Msg,Loc1 + 1)>
										<CFSET ErrCol=Mid(Msg,Loc1 + 1,Loc2 - Loc1 - 1)>
										<CFSET Msg=Msg & "<br>Increase the size of the column and re-load this page.<br><br>" &
														 "ALTER TABLE backblaze.#Cache[Models.Model[ModelIDx]].SchemaName# CHANGE COLUMN `#ErrCol#` `#ErrCol#` BIGINT UNSIGNED NULL DEFAULT NULL;<br>" &
														 "UPDATE backblaze2.models SET Compressed=0 WHERE ModelID=#Cache[Models.Model[ModelIDx]].ModelID#;<br><br>">
									</CFIF>
									<CFOUTPUT><hr>#Msg#</CFOUTPUT>
									<CFSET Abort=1>
								</CFCATCH>
							</CFTRY>
							<CFOUTPUT> done </CFOUTPUT><CFFLUSH>
							<CFSET Rows=ArrayNew(1)>
							<CFSET RowIDx=0>
						</CFIF>
					</CFLOOP>
					<CFIF ArrayLen(Rows)>
						<CFOUTPUT> Inserting data (#Trim(NumberFormat(ArrayLen(Rows),"9,999"))#)</CFOUTPUT><CFFLUSH>
						<CFTRY>
							<CFQUERY datasource="#DSN#">#PatchSQL# #PreserveSingleQuotes(ArrayToList(Rows))#</CFQUERY>
							<CFCATCH Type="Database">
								<CFSET Msg=CFCATCH.Message>
								<CFIF Left(Msg,46) EQ "Data truncation: Out of range value for column">
									<CFSET Loc1=Find(" at row",Msg)>
									<CFIF Loc1 GT 0>
										<CFSET Msg=Left(Msg,Loc1 - 1)>
									</CFIF>
									<CFSET Loc1=Find("'",Msg)>
									<CFSET Loc2=Find("'",Msg,Loc1 + 1)>
									<CFSET ErrCol=Mid(Msg,Loc1 + 1,Loc2 - Loc1 - 1)>
									<CFSET Msg=Msg & "<br>Increase the size of the column and re-load this page.<br><br>" &
													 "ALTER TABLE backblaze.#Cache[Models.Model[ModelIDx]].SchemaName# CHANGE COLUMN `#ErrCol#` `#ErrCol#` BIGINT UNSIGNED NULL DEFAULT NULL;<br>" &
													 "UPDATE backblaze2.models SET Compressed=0 WHERE ModelID=#Cache[Models.Model[ModelIDx]].ModelID#;<br><br>">
								</CFIF>
								<CFOUTPUT><hr>#Msg#</CFOUTPUT>
								<CFSET Abort=1>
							</CFCATCH>
						</CFTRY>
					</CFIF>
					<CFOUTPUT> done<br></CFOUTPUT><CFFLUSH>
				</CFIF>
			</CFIF>

			<CFIF SerialIDsInserted NEQ "">
				<!--- Flush SerialIDsInserted --->
				<CFQUERY datasource="#DSN#">
					UPDATE backblaze2.serial_numbers SET FirstDate=NULL WHERE SerialID IN (#SerialIDsInserted#)
				</CFQUERY>
				<CFSET SerialIDsInserted="">
			</CFIF>

			<CFIF Abort>
				<CFABORT>
			</CFIF>

		</CFLOOP>
		<CFSET StructDelete(Variables,"DataArray")>
		<CFSET StructDelete(Variables,"Data")>
	</CFIF>

	<!--- Delete large variables for GC --->
	<CFSET StructDelete(Variables,"CSV")>

</CFLOOP>

<CFSET Out("Audit complete")>

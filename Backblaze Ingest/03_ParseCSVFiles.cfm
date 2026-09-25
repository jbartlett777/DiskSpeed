<!---
This program reads in the raw BackBlaze data files and generates SQL for use in loading the drive data. SQL is broken up by drive model.
--->

<!--- Load current model databases --->
<CFQUERY name="qDriveModelList" datasource="#DSN#">
	SHOW TABLES FROM backblaze
</CFQUERY>
<CFSET DriveModelList=ValueList(qDriveModelList.TABLES_IN_BACKBLAZE)>

<!--- Generate create schema/table base --->
<CFQUERY name="SmartIDs" datasource="#DSN#">
	SELECT ID FROM backblaze2.smart ORDER BY ID
</CFQUERY>

<CFSET SmartIDList=ValueList(SmartIDs.ID)>
<CFFILE action="read" file="#RootDir#/CreateDriveTable.sql" variable="CreateSQL">
<CFLOOP index="CR" from="1" to="#SmartIDs.RecordCount#">
	<CFSET CreateSQL=Replace(CreateSQL,"xxxx","	N_#SmartIDs.ID[CR]# BIGINT unsigned DEFAULT NULL,")>
	<CFSET CreateSQL=Replace(CreateSQL,"xxxx","	R_#SmartIDs.ID[CR]# BIGINT unsigned DEFAULT NULL,")>
</CFLOOP>
<CFSET CreateSQL=Replace(CreateSQL,"xxxx" & Chr(10),"","All")>


<!--- Fetch Files sorted by name --->
<CFDIRECTORY action="list" directory="#SourceDir#" name="Files" sort="name asc" filter="*.csv">

<!--- Load in previous parsed files --->
<CFSET ParsedFiles=StructNew("ordered")>
<CFIF FileExists("#ModelDir#/ParsedFiles.json")>
	<CFFILE action="Read" file="#ModelDir#/ParsedFiles.json" variable="JSON">
	<CFIF IsJSON(JSON)>
		<CFSET ParsedFiles=DeserializeJSON(JSON)>
	<CFELSE>
		<CFOUTPUT>Bad ParsedFiles.json file</CFOUTPUT>
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
<div id="Status">Caching Serial Number table</div>
</CFOUTPUT>
<CFFLUSH>

<!--- Cache serial number table in memory so we don't have to do seperate DB lookups later --->
<CFSET Out("Building Serial Number cache struct")>
<CFSET Cache=CacheDrives()>

<!--- Cache existing directories --->
<CFSET Out("Loading existing directory structure")>
<CFDIRECTORY action="list" directory="#ModelDir#" type="Dir" recurse="true" name="tmpCachePaths">
<!--- Combine path & directory into one --->
<CFQUERY name="tmpCachePaths2" dbtype="Query">
	SELECT Directory + '/' + Name as Path
	FROM tmpCachePaths
</CFQUERY>
<CFSET CachePaths=ListToArray(Replace(ValueList(tmpCachePaths2.Path,"|"),"\","/","All"),"|")>

<!--- Drive Data --->
<CFSET DriveData=StructNew()>

<!--- Loop over files --->
<CFLOOP index="FileIdx" from="1" to="#Files.RecordCount#">
	<CFIF FileExists("#SourceDir#/#Files.Name[FileIdx]#") EQ "NO">
		<CFBREAK>
	</CFIF>
	<CFIF StructKeyExists(ParsedFiles,Files.Name[FileIdx])>
		<!--- File has already been loaded, skip to next file --->
		<CFCONTINUE>
	</CFIF>
	<CFSET ParsedFiles[Files.Name[FileIdx]]="">

	<CFSET FileDate=ParseDateTime(ListDeleteAt(Files.Name[FileIdx],ListLen(Files.Name[FileIdx],"."),"."))>
	<CFSET FileDate2=ListDeleteAt(Files.Name[FileIdx],ListLen(Files.Name[FileIdx],"."),".")>

	<!--- Flag to indicate we need to clear out the partition ID's because the table was altered --->
	<CFSET TableAltered=0>
	<!--- SQL used to stub out new drives to identify what partition they will insert into --->
	<CFSET SerialStubSQL=StructNew()>

	<!--- Define smart cache --->
	<CFSET SMARTData=StructNew("ordered")>
	<!--- Load files into a variable --->
	<CFSET Out("Loading file #Files.Name[FileIdx]#")>
	<CFFILE action="Read" file="#SourceDir#\#Files.Name[FileIdx]#" variable="Raw">
	<!--- Convert to Array --->
	<CFSET SMART=ListToArray(StripCR(Raw),Chr(10))>
	<CFSET Raw="">
	<!--- Get Data Locations --->
	<CFSET DateLoc=ListFindNoCase(SMART[1],"date")>
	<CFSET SerialLoc=ListFindNoCase(SMART[1],"serial_number")>
	<CFSET ModelLoc=ListFindNoCase(SMART[1],"model")>
	<CFSET CapacityLoc=ListFindNoCase(SMART[1],"capacity_bytes")>
	<CFSET FailureLoc=ListFindNoCase(SMART[1],"failure")>
	<CFIF DateLoc EQ 0 OR SerialLoc EQ 0 OR ModelLoc EQ 0 OR CapacityLoc EQ 0 OR FailureLoc EQ 0>
		<CFOUTPUT>Missing headers</CFOUTPUT>
		<CFABORT>
	</CFIF>

	<CFSET HeaderRow=SMART[1]>
	<CFSET MasterHeaderLen=ListLen(HeaderRow)> <!--- Used to check if a data row doesn't have the correct number of columns --->
	<CFSET ArrayDeleteAt(SMART,1)>
	<!--- Get first position of smart values --->
	<CFSET SMARTLoc=Min(ListFindNoCase(HeaderRow,"smart_1_normalized"),ListFindNoCase(HeaderRow,"smart_1_raw"))>
	<!--- Remove all columns from the header prior to the SMART values except for date & failure --->
	<CFLOOP index="i" from="1" to="#SmartLoc - 1#">
		<CFSET HeaderRow=ListDeleteAt(HeaderRow,1)>
	</CFLOOP>
	<CFSET HeaderRow="SerialID,Date,Failure," & HeaderRow>

	<!--- Change SMART headers to a shorter version --->
	<CFLOOP index="s" from="1" to="#SmartIDs.RecordCount#">
		<CFSET HeaderRow=ReplaceNoCase(HeaderRow,"smart_#SmartIDs.ID[s]#_normalized","N_#SmartIDs.ID[s]#")>
		<CFSET HeaderRow=ReplaceNoCase(HeaderRow,"smart_#SmartIDs.ID[s]#_Raw","R_#SmartIDs.ID[s]#")>
	</CFLOOP>
	<CFSET HeaderRowHash=Hash36(HeaderRow)>
	<CFSET HeaderLen=ListLen(HeaderRow)>

	<!--- Check for new SMART headers that we don't know about --->
	<CFIF Find("raw",HeaderRow)>
		<CFOUTPUT>New SMART columns found<br>#HeaderRow#</CFOUTPUT><CFABORT>
	</CFIF>

	<CFSET SchemaNames=StructNew("ordered")>
	<CFSET NewModels=StructNew("ordered")>

	<!--- Sort the SMART data by date & serial number --->
	<CFSET ArraySort(SMART,"textnocase")>

	<CFSET TotalRows=ArrayLen(SMART)>
	<CFSET LastPer=""> <!--- Tracks the last percentage, if's different from current, update and display progress to user --->
	<CFLOOP index="i" from="1" to="#TotalRows#">
		<CFSET CurrRow=SMART[i]>
		<!--- ListDeleteAt does not support null/empty values, so put one in --->
		<CFSET CurrRow=Replace(CurrRow,",,",",N,","All")>
		<CFSET CurrRow=Replace(CurrRow,",,",",N,","All")>
		<CFIF Right(CurrRow,1) EQ ",">
			<CFSET CurrRow=CurrRow & "N">
		</CFIF>
		<!--- Check to see if row has the correct number of columns --->
		<CFIF ListLen(CurrRow) NEQ MasterHeaderLen>
			<CFOUTPUT>Row #i# of #SourceDir#/#Files.Name[FileIdx]# has incorrect number of columns: #CurrRow#</CFOUTPUT>
			<CFABORT>
		</CFIF>
		<!--- Update user on progress --->
		<CFSET Per=Int(i / TotalRows / 0.01)>
		<CFIF LastPer NEQ Per>
			<CFSET LastPer=Per>
			<CFSET Out("Processing file #Files.Name[FileIdx]# (#Per#%)")>
		</CFIF>
		<!--- Parse line for basic drive info --->
		<CFSET Model=ListGetAt(CurrRow,ModelLoc,",",true)>
		<CFSET Serial=ListGetAt(CurrRow,SerialLoc,",",true)>
		<CFSET Capacity=ListGetAt(CurrRow,CapacityLoc,",",true)>
		<CFSET Failure=ListGetAt(CurrRow,FailureLoc,",",true)>
		<CFIF Failure NEQ 0>
			<CFSET Failure=1>
		</CFIF>
		<!--- Remove double-space from Model, ie: "WDC  WUH721816ALE6L0" --->
		<CFSET Model=Trim(Replace(Model,"  "," ","All"))>

		<CFIF StructKeyExists(Cache,Model)>
			<CFSET SchemaName=Cache[Model].SchemaName>
		<CFELSE>
			<CFSET SchemaName=SafeSchemaName(Model)>
		</CFIF>

		<!--- Create Schema DB if not existing --->
		<CFIF StructKeyExists(DriveData,Model) EQ "NO">
			<CFSET DriveData[Model]=StructNew()>
			<CFIF ListFindNoCase(DriveModelList,SchemaName) EQ 0>
				<CFSET SQL=CreateSQL>
				<CFSET SQL=Replace(SQL,"[Model]",SchemaName,"All")>
				<CFSET FN="_Create_#SchemaName#.sql">
				<CFIF AppServer EQ "Lucee">
					<CFFILE action="Write" file="#ModelDir#/SQL/#Model#/#FN#" output="#SQL#" mode="666" createpath="true">
				<CFELSE>
					<CFSET CreatePath("#ModelDir#/SQL/#Model#")>
					<CFFILE action="Write" file="#ModelDir#/SQL/#Model#/#FN#" output="#SQL#" mode="666">
				</CFIF>
				<!--- Execute SQL --->
				<CFLOOP index="CurrSQL" list="#SQL#" delimiters=";">
					<CFIF Trim(CurrSQL) NEQ "">
						<CFQUERY datasource="#DSN#">#PreserveSingleQuotes(CurrSQL)#</CFQUERY>
					</CFIF>
				</CFLOOP>
				<CFOUTPUT>New model found: #Model#<br></CFOUTPUT>
			</CFIF>
		</CFIF>
		<CFIF StructKeyExists(DriveData[Model],Serial) EQ "NO">
			<CFSET DriveData[Model][Serial]=ArrayNew(1)>)
		</CFIF>

		<!--- Check for Model --->
		<CFIF StructKeyExists(Cache,Model)>
			<CFSET ModelID=Cache[Model].ModelID>
			<CFIF StructKeyExists(Cache[Model].Capacity,Capacity)>
				<CFSET Cache[Model].Capacity[Capacity]=Cache[Model].Capacity[Capacity] + 1>
			<CFELSE>
				<CFSET Cache[Model].Capacity[Capacity]=1>
			</CFIF>
		<CFELSE>
			<!--- Insert Model ID --->
			<CFQUERY Result="Result" datasource="#DSN#">
				INSERT INTO backblaze2.Models (Model, SchemaName)
				VALUES (
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Model#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SchemaName#">
					)
			</CFQUERY>
			<CFSET ModelID=Result.GeneratedKey>
			<CFSET Cache[Model]=StructNew()>
			<CFSET Cache[Model].ModelID=ModelID>
			<CFSET Cache[Model].SchemaName=SchemaName>
			<CFSET Cache[Model].Capacity=StructNew()>
			<CFSET Cache[Model].Capacity[Capacity]=1>
		</CFIF>

		<!--- Check for Serial Number --->
		<CFIF StructKeyExists(Cache[Model],Serial)>
			<CFSET SerialID=Cache[Model][Serial].SerialID>
		<CFELSE>
			<!--- Insert Serial ID --->
			<CFQUERY result="Result" datasource="#DSN#">
				INSERT INTO backblaze2.serial_numbers (ModelID, Serial_Number, FirstDate, Failed)
				VALUES (
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#ModelID#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Serial#">,
						<cfqueryparam CFSQLType="CF_SQL_Date" value="#CreateODBCDate(FileDate)#">,
						<cfqueryparam CFSQLType="CF_SQL_BIT" value="#Failure#">
						)
			</CFQUERY>
			<CFSET SerialID="000" & Replace(RJustify(Result.GeneratedKey,8)," ","0","All")> <!--- Zero pad for sorting --->
			<!--- Add row to cache --->
			<CFSET Cache[Model][Serial]=StructNew()>
			<CFSET Cache[Model][Serial].SerialID="000|" & SerialID> <!--- Partition (if any) isn't known yet so these drives will be inserted ad-hock. Model DB typically won't be partitioned on first assignment so likely not too much of an issue --->
			<CFSET Cache[Model][Serial].FirstDate=FileDate>
			<CFSET Cache[Model][Serial].LastDate="">
			<CFSET Cache[Model][Serial].Failed=Failure>
			<CFSET Cache[Model][Serial].Dupe=0>
		</CFIF>
		<!--- Remove non-SMART values --->
		<CFLOOP index="d" from="1" to="#SMARTLoc - 1#">
			<CFSET CurrRow=ListDeleteAt(CurrRow,1)>
		</CFLOOP>
		<!--- Strip NULLs back out --->
		<CFSET CurrRow=Replace(CurrRow,"N","","All")>

		<CFSET CurrRow="#SerialID#,#FileDate2#,#Failure#," & CurrRow>

		<CFIF ListLen(CurrRow,",",true) NEQ HeaderLen>
			<CFOUTPUT>Row length mismatch in file #Files.Name[FileIdx]# for model #Model# and serial #Serial#.<br>
			Header: #HeaderLen#, Row: #ListLen(CurrRow,",",true)#<br>
			#HeaderRow#<br>
			#CurrRow#
			<table border="1" cellpadding="0" cellspacing="0">
				<tr>
					<CFLOOP index="q" from="1" to="#ListLen(HeaderRow,',',true)#">
						<td>#ListGetAt(HeaderRow,q,",",true)#&nbsp;</td>
					</CFLOOP>
				</tr>
				<tr>
					<CFLOOP index="q" from="1" to="#ListLen(CurrRow,',',true)#">
						<td>#ListGetAt(CurrRow,q,",",true)#&nbsp;</td>
					</CFLOOP>
				</tr>
			</table>
			</CFOUTPUT>
			<CFABORT>
		</CFIF>

		<CFSET DriveData[Model][Serial][ArrayLen(DriveData[Model][Serial]) + 1]=CurrRow>

		<CFSET Cache[Model][Serial].LastDate=FileDate>

	</CFLOOP>

	<!--- Flush DriveData if needed. DriveData broken down by serial number because it was MUCH faster than breaking down the arrays by model only. But we'll save the entire model
		  in one file because having 30k+ directories can really slow things down --->
	<CFSET ModelList=ListSort(StructKeyList(DriveData),"textnocase","asc")>
	<CFIF FileIdx EQ Files.RecordCount OR DaysInMonth(FileDate) EQ ListLast(FileDate2,"-") OR (Int(DaysInMonth(FileDate) / 2)) EQ ListLast(FileDate2,"-")> <!--- Purge half way through month, on last day of month or end of files --->
		<CFLOOP index="CurrModel" list="#ModelList#">
			<CFSET Out("Combining drives for #CurrModel#")>
			<CFSET ModelArray=ArrayNew(1)>
			<CFLOOP index="CurrSerial" list="#StructKeyList(DriveData[CurrModel])#">
				<CFSET ArrayAppend(ModelArray,DriveData[CurrModel][CurrSerial],true)>
			</CFLOOP>
			<CFSET DriveData[CurrModel]=StructNew()> <!--- Empty serial struct --->
			<CFSET Out("Sorting data for #CurrModel# by partition & serial number")>
			<CFSET ArraySort(ModelArray,"text","asc")>
			<CFSET Data=ArrayToList(ModelArray,Chr(10))>
			<CFSET Data=Replace(Data,Chr(10) & Chr(10),Chr(10),"All")> <!--- Eliminate blank rows if there are gaps in dates --->
			<CFSET Data=Replace(Data,Chr(10) & Chr(10),Chr(10),"All")>
			<CFSET Data=REReplace(Data,"\d{3}\|0+","","All")> <!--- Strip out partition id and leading zeros on the Serial ID --->
			<CFSET Data=REReplace(Data,"\n0+",Chr(10),"All")> <!--- Strip out leading zeros still left --->
			<CFSET BadFailedFlag=REMatch("(?m)^\d{4}-[^,]*,[^,]*,[^,]*,(?![01](?:,|$))[^,]*",Data)>
			<CFIF ArrayLen(BadFailedFlag)>
				<cfdump var=#BadFailedFlag#>
				<!--- The failed flag should be binary (0/1) but sometimes isn't. Replace such values with a 1 --->
				<CFLOOP index="i" from="1" to="#ArrayLen(BadFailedFlag)#">
					<CFSET Rep=ListAppend(ListDeleteAt(BadFailedFlag[i],5),"1")> <!--- Remove invalid failed flag and replace with a 1 --->
					<CFSET Data=Replace(Data,BadFailedFalg[i],Rep)> <!--- Replace the bad data with good data --->
				</CFLOOP>
			</CFIF>
			<CFIF Trim(Data) NEQ "">
				<CFSET Out("Saving data for #CurrModel# by serial number")>
				<CFSET Path="#ModelDir#/Data/#CurrModel#">
				<!--- Build a FN that starts with the SerialID and the first date in the batch --->
				<CFSET NewPath=CreatePath(Path)>
				<CFSET FN=Path & "/" & FileDate2 & "_#HeaderRowHash#" & ".txt"> <!--- Break files up into 1/2 month or they could grow too large to load later --->
				<CFIF NewPath EQ true OR FileExists(FN) EQ "NO">
					<!--- New file, write header row --->
					<CFFILE action="Write" file="#FN#" output="#HeaderRow##Chr(10)#" mode="666" addnewline="No">
				</CFIF>
				<CFFILE action="Append" file="#FN#" output="#Data#" mode="666">
			</CFIF>
		</CFLOOP>
		<!--- Update parsed files --->
		<CFSET JSON=SerializeJSON(ParsedFiles)>
		<CFFILE action="write" file="#ModelDir#/ParsedFiles.json" output="#JSON#" addnewline="NO" mode="666">
	</CFIF>

	<!--- Update model capacity --->
	<CFQUERY name="Models" datasource="#DSN#">
		SELECT ModelID, Model
		FROM backblaze2.Models
		WHERE Capacity IS NULL
	</CFQUERY>
	<CFLOOP index="ModelIdx" from="1" to="#Models.RecordCount#">
		<!--- Get the capacity with the most number of drives, min 5 --->
		<CFSET MaxCapacity=0>
		<CFIF StructKeyExists(Cache,Models.Model[ModelIdx])>
			<CFLOOP index="CurrCapacity" list="#StructKeyList(Cache[Models.Model[ModelIdx]].Capacity)#">
				<CFIF Cache[Models.Model[ModelIdx]].Capacity[CurrCapacity] GTE 5>
					<CFSET MaxCapacity=Max(MaxCapacity,CurrCapacity)>
				</CFIF>
			</CFLOOP>
		</CFIF>
		<CFIF MaxCapacity GT 0>
			<CFQUERY datasource="#DSN#">
				UPDATE backblaze2.Models
				SET Capacity=<cfqueryparam CFSQLType="CF_SQL_BIGINT" value="#MaxCapacity#">
				WHERE ModelID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[ModelIdx]#">
			</CFQUERY>
		</CFIF>
	</CFLOOP>
</CFLOOP>


<CFSET Out("Done")>

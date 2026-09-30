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
</head>
<body>
<style type="text/css">
body {
    font-family: "Courier New", Courier, monospace;
    font-size: 10pt;
}
</style>
Start at #TimeFormat(Now(),"HH:mm:ss")#<br>
<div id="Status">&nbsp;</div>
</CFOUTPUT>

<CFQUERY name="Databases" datasource="#DSN#">
	SELECT SchemaName
	FROM backblaze2.Models
	WHERE `ignore`=0
	ORDER BY SchemaName
</CFQUERY>

<CFSET Keys="SerialID,date,failure,Age">
<CFSET SQL="">

<CFLOOP index="CR" from="1" to="#Databases.RecordCount#">
	<!--- Get indexes on table --->
	<CFTRY>
		<CFQUERY name="CheckIndex" datasource="#DSN#">
		SHOW INDEX FROM backblaze.`#Databases.SchemaName[CR]#`;
		</CFQUERY>
		<CFCATCH Type="Any">
			<!--- Model doesn't exist, likely from puring data & tables but leaving the model/serial number tables intact, so skip this model --->
			<CFCONTINUE>
		</CFCATCH>
	</CFTRY>

	<CFSET SQL2="">
	<CFLOOP index="CurrKey" list="#Keys#">
		<CFIF ListFindNoCase("SerialID",CurrKey) EQ 0>
			<!--- Check for index --->
			<CFQUERY name="ChkIndex" dbtype="Query">
				SELECT key_name
				FROM CheckIndex
				WHERE key_name='ix_#CurrKey#'
			</CFQUERY>
			<CFIF ChkIndex.RecordCount EQ 0>
				<CFSET SQL2=ListAppend(SQL2,"ADD INDEX `ix_#CurrKey#` (`#CurrKey#` ASC) VISIBLE","|")>
			</CFIF>
		</CFIF>
	</CFLOOP>

	<CFIF SQL2 NEQ "">
		<CFSET SQL=SQL & "ALTER TABLE backblaze.#Databases.SchemaName[CR]#" & Chr(10) & Replace(SQL2,"|",",#Chr(10)#","All") & ";">
	</CFIF>
</CFLOOP>

<CFSET SQL=Replace(SQL,"|",",","All")>
<CFSET SQL=Replace(SQL,"(`SerialID` ASC,`SerialID` ASC)","(`SerialID` ASC)","All")>

<CFOUTPUT>
<CFIF SQL EQ "">
	No indexes to create
<CFELSE>
	<CFSET i=0>
	<CFSET TotalSQL=ListLen(SQL,";")>
	<CFLOOP index="CurrSQL" list="#SQL#" delimiters=";">
		<CFSET i=i+1>
		<CFSET Out("Adding index (#i#/#TotalSQL#)<br><br>" & Replace(CurrSQL,Chr(10),"<br>","All"))>
		<CFQUERY datasource="#DSN#">
			#PreserveSingleQuotes(CurrSQL)#
		</CFQUERY>
	</CFLOOP>
	<CFSET Out("Done creating indexes")>
</CFIF>
</CFOUTPUT>

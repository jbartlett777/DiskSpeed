<!--- This file preps the tables for importing data by dropping extra indexes and ensuring a unique constraint on the Serial Number ID & Date
	  exists to prevent against duplicates on bulk loading --->


<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<div id="x">&nbsp;</div>
<script>
function o(txt) {
	document.getElementById('x').innerHTML=txt;
}
</script>
</CFOUTPUT>

<CFQUERY name="Databases" datasource="#DSN#">
	SELECT SchemaName
	FROM backblaze2.Models
	WHERE `ignore`=0
	ORDER BY SchemaName
</CFQUERY>

<CFLOOP index="CR" from="1" to="#Databases.RecordCount#">
	<CFSET SQL2="">
	<!--- Get indexes on table --->
	<CFTRY>
		<CFQUERY name="CheckIndex" datasource="#DSN#">
			SHOW INDEX FROM backblaze.#Databases.SchemaName[CR]#
		</CFQUERY>
		<CFQUERY name="UniqIndex" dbtype="query">
			SELECT DISTINCT key_name
			FROM CheckIndex
			ORDER BY key_name
		</CFQUERY>
		<CFCATCH Type="Any">
			<!--- Model doesn't exist, likely from puring data & tables but leaving the model/serial number tables intact, so skip this model --->
			<CFCONTINUE>
		</CFCATCH>
	</CFTRY>
	<!--- Drop all indexes except for PRIMARY, ix_date, and uq_serial_date --->
	<CFLOOP index="i" from="1" to="#UniqIndex.RecordCount#">
		<CFIF ListFindNoCase("PRIMARY,uq_serial_date,ix_date",UniqIndex.key_name[i]) EQ 0>
			<CFSET Out="Model #Databases.SchemaName[CR]# (#CR#/#Databases.RecordCount#): DROP INDEX #UniqIndex.key_name[i]#">
			<CFOUTPUT><script>o('#EncodeForJavascript(Out)#');</script></CFOUTPUT><CFFLUSH>
			<CFQUERY datasource="#DSN#">
				DROP INDEX #UniqIndex.key_name[i]# ON backblaze.#Databases.SchemaName[CR]#
			</CFQUERY>
		</CFIF>
	</CFLOOP>
	<!--- Check to see if uq_serial_date exists --->
	<CFQUERY name="ChkIdx" dbtype="Query">
		SELECT *
		FROM CheckIndex
		WHERE key_name='uq_serial_date'
	</CFQUERY>
</CFLOOP>

<CFOUTPUT><script>o('Process completed.');</script></CFOUTPUT><CFFLUSH>
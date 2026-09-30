<CFQUERY name="Models" datasource="#DSN#">
	SELECT ModelID, Model, SchemaName
	FROM backblaze2.models
	ORDER BY Model
</CFQUERY>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<div id="x">.</div>
<script>
function o(txt) {
	document.getElementById('x').innerHTML=txt;
}
</script>
</CFOUTPUT>

<CFLOOP index="i" from="1" to="#Models.RecordCount#">
	<CFSET SchemaName=SafeSchemaName(Models.Model[i])>
	<CFTRY>
		<!--- Check for Null FirstDate, set if found --->
		<CFQUERY name="ChkNULL" datasource="#DSN#">
			SELECT COUNT(1) As Cnt
			FROM backblaze2.serial_numbers
			WHERE FirstDate IS NULL
		</CFQUERY>
		<CFIF Val(ChkNULL.Cnt) GT 0>
		<CFOUTPUT><script>o('Setting First Date for model #EncodeForJavascript(Models.Model[i])# (#i#/#Models.RecordCount#)');</script></CFOUTPUT><CFFLUSH>
			<CFQUERY datasource="#DSN#">
				UPDATE backblaze2.serial_numbers s
				SET s.FirstDate=(SELECT MIN(`Date`) FROM backblaze.#SchemaName# WHERE SerialID = s.SerialID)
				WHERE s.ModelID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[i]#">
				  AND s.FirstDate IS NULL
			</CFQUERY>
		</CFIF>
		<CFOUTPUT><script>o('Setting Last Date for model #EncodeForJavascript(Models.Model[i])# (#i#/#Models.RecordCount#)');</script></CFOUTPUT><CFFLUSH>
		<CFQUERY datasource="#DSN#">
			UPDATE backblaze2.serial_numbers s
			SET s.LastDate=(SELECT MAX(`Date`) FROM backblaze.#SchemaName# WHERE SerialID = s.SerialID)
			WHERE s.ModelID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[i]#">
		</CFQUERY>
		<CFCATCH Type="Any">
			<!--- Model doesn't exist, likely from puring data & tables but leaving the model/serial number tables intact, so skip this model --->
			<CFCONTINUE>
		</CFCATCH>
	</CFTRY>

	<CFOUTPUT><script>o('Setting ages for model #EncodeForJavascript(Models.Model[i])# (#i#/#Models.RecordCount#)');</script></CFOUTPUT><CFFLUSH>
	<CFQUERY datasource="#DSN#">
		UPDATE backblaze.#SchemaName# s
		SET s.Age=(SELECT TIMESTAMPDIFF(day,FirstDate,s.Date) FROM backblaze2.serial_numbers WHERE SerialID = s.SerialID)
		WHERE s.Age IS NULL;
	</CFQUERY>

</CFLOOP>

<!--- Get Max Date --->
<CFQUERY name="LastDate" datasource="#DSN#">
	SELECT Max(LastDate) as LastDate
	FROM backblaze2.serial_numbers
</CFQUERY>

<CFOUTPUT><script>o('Clearing drives with the last date of #DateFormat(LastDate.LastDate,"yyyy-mm-dd")#');</script></CFOUTPUT><CFFLUSH>

<CFQUERY datasource="#DSN#">
	UPDATE backblaze2.serial_numbers
	SET LastDate=NULL
	WHERE LastDate=#CreateODBCDate(LastDate.LastDate)#
</CFQUERY>

<CFLOOP index="i" from="1" to="#Models.RecordCount#">
	<!--- Get all distinct serial numbers for the current model --->
	<CFQUERY name="SerialIDs" datasource="#DSN#">
		SELECT DISTINCT FirstDate
		FROM backblaze2.serial_numbers
		WHERE ModelID=#Models.ModelID[i]#
	</CFQUERY>
</CFLOOP>



<CFOUTPUT><script>o('Done setting the last active date on drives');</script></CFOUTPUT><CFFLUSH>

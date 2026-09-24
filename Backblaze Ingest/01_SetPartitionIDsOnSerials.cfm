<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<script language="JavaScript">
function sc()
{
	window.scrollBy(0,9999);
}
</script>
</CFOUTPUT>

<CFSET ProcessedModels="0"> <!--- List of Model ID's already processed through this run --->

<CFSET Looper=0>
<CFLOOP condition="NOT Looper">

	<!--- Get a model that has unmarked serials and set the partition ID on those serials --->
	<CFQUERY name="Model" datasource="#DSN#">
		SELECT s.SerialID, s.ModelID, m.Model, s.Serial_Number
		FROM backblaze2.serial_numbers s
		INNER JOIN backblaze2.models m ON m.ModelID=s.ModelID -- AND m.Ignore=0 AND (m.PartitionCount IS NULL OR m.PartitionCount > 0)
		WHERE s.ModelID NOT IN (#ProcessedModels#)
		AND s.PartitionID IS NULL
		ORDER BY s.ModelID, s.SerialID
		LIMIT 0,1
	</CFQUERY>

	<CFIF Model.RecordCount EQ 0>
		<CFOUTPUT>#TS()# No partition keys need assignment<br><script>sc();</script></CFOUTPUT><CFFLUSH>
		<CFABORT>
	</CFIF>

	<!--- Get all unmarked serials from that model --->
	<CFQUERY name="Serials" datasource="#DSN#">
		SELECT SerialID
		FROM backblaze2.serial_numbers
		WHERE ModelID=#Model.ModelID#
		AND PartitionID IS NULL
		ORDER BY SerialID
	</CFQUERY>

	<CFSET SchemaName=SafeSchemaName(Model.Model)>

	<CFOUTPUT>#TS()# Processing #Model.Model# (Model ID: #Model.ModelID#)<br><script>sc();</script></CFOUTPUT><CFFLUSH>

	<!--- Fetch schema information --->
	<CFQUERY name="SchemaInfo" datasource="#DSN#">
		DESCRIBE TABLE backblaze.#SchemaName#
	</CFQUERY>

	<CFSET SQL="">
	<CFSET ProcessedModels=ListAppend(ProcessedModels,Model.ModelID)>
	<CFIF SchemaInfo.Partitions NEQ "">
		<CFOUTPUT>#TS()# Updateing partition reference<br><script>sc();</script></CFOUTPUT><CFFLUSH>
		<CFQUERY name="UpdatePartitionCount" datasource="#DSN#">
			UPDATE backblaze2.models SET PartitionCount=#ListLen(SchemaInfo.Partitions)# WHERE ModelID=#Model.ModelID#
		</CFQUERY>
		<CFLOOP index="CurrPart" list="#SchemaInfo.Partitions#">
			<!--- Get all Serial ID's on each partition --->
			<CFQUERY name="PartitionSerials" datasource="#DSN#">
				SELECT DISTINCT SerialID
				FROM backblaze.#SchemaName# PARTITION (#CurrPart#)
				WHERE SerialID IN (#ValueList(Serials.SerialID)#)
				ORDER BY SerialID
			</CFQUERY>
			<CFIF PartitionSerials.RecordCount GT 0>
				<CFQUERY datasource="#DSN#">
					UPDATE backblaze2.serial_numbers SET PartitionID=#Mid(CurrPart,2,99)# WHERE SerialID IN (#ValueList(PartitionSerials.SerialID)#)
				</CFQUERY>
			</CFIF>
		</CFLOOP>
	<CFELSE>
		<CFQUERY name="UpdatePartitionCount" datasource="#DSN#">
			UPDATE backblaze2.models SET PartitionCount=0 WHERE ModelID=#Model.ModelID#
		</CFQUERY>
		<CFOUTPUT>#TS()# No partitions to update<br><script>sc();</script></CFOUTPUT><CFFLUSH>
	</CFIF>
	<CFIF SQL EQ "">
	<CFELSE>
		<CFQUERY datasource="#DSN#">#SQL#</CFQUERY>
	</CFIF>
</CFLOOP>

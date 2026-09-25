<!--- The purpse of this script is to validate all tables to see if they have been corrupted --->

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

<CFQUERY name="Databases" datasource="#DSN#">
	SELECT SchemaName
	FROM backblaze2.Models
	WHERE `ignore`=0
	ORDER BY SchemaName
</CFQUERY>

<CFSET StartAtDatabase="st12000nm000j">
<CFSET Ok=0>

<CFLOOP index="CR" from="1" to="#Databases.RecordCount#">
	<CFIF NOT OK>
		<CFIF Databases.Database[CR] EQ StartAtDatabase>
			<CFSET OK=1>
		<CFELSE>
			<CFCONTINUE>
		</CFIF>
	</CFIF>
	<CFLOOP index="t" from="1" to="#Tables.Recordcount#">
		<CFSET TableName=Tables[Col][t]>
		<CFOUTPUT>#TimeFormat(Now(),"HH:mm:ss")# #Databases.Database[CR]#.#TableName#: <script>sc();</script></CFOUTPUT><CFFLUSH>
		<CFQUERY name="Chk" datasource="#DSN#">
			CHECK TABLE backblaze.`#Databases.Database[CR]#`
		</CFQUERY>
		<CFOUTPUT>#Chk.Msg_text#<br></CFOUTPUT>
	</CFLOOP>
</CFLOOP>

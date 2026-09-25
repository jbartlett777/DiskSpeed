<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET CheckSessionID=Session.RequestID>
</cflock>
<CFIF CheckSessionID NEQ SessionID>
	<CFOUTPUT>
	<script language="JavaScript">
	parent.SubTest();
	parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Aborted';
	parent.document.getElementById('Progress_#ControllerID#_td').style.display='none';
	parent.document.getElementById('Speed_#ControllerID#').innerHTML='';
	</script>
	#TS()# Kill flag found
	</CFOUTPUT>
	<CFFLUSH>
	<!--- Run kill fio jobs on any PIDs --->
	<CFSET PIDList="">
	<CFDIRECTORY action="list" directory="#OutDir#" name="PIDs" filter="*.pid">
	<CFLOOP index="PIDCR" from="1" to="#PIDs.RecordCount#">
		<CFSET PIDList=ListAppend(PIDList,ListFirst(PIDs.Name[PIDCR],".")," ")>
	</CFLOOP>
	<CFIF PIDLIst NEQ "">
		<!---<cfoutput>/bin/kill -9 #PIDList#<br></CFOUTPUT>--->
		<CFTRY>
			<CFEXECUTE name="/bin/kill" arguments="-9 #PIDList#" timeout="999"></CFEXECUTE>
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>
	</CFIF>

	<cflock name="DeleteFile" type="exclusive" throwontimeout="false" timeout="10">
		<CFIF FileExists("#BenchmarkFlagFN#")>
			<CFFILE action="delete" file="#BenchmarkFlagFN#">
		</CFIF>
	</cflock>
	<CFINCLUDE Template="RemoveTempFiles.cfm">
	<CFABORT>
</CFIF>

<CFDIRECTORY action="list" directory="#SaveDir#/pids" type="file" name="PIDList">
<CFIF PIDList.RecordCount GT 0>
	<CFSET PIDID=GetTickCount()>
	<CFOUTPUT><div id="Div_#PIDID#">There was a potential interruption of a previous drive read test or it is currently still in progress. Cleaning up...</div></CFOUTPUT>
	<CFFLUSH>
	<CFSET Out="">
	<CFLOOP index="CR" from="1" to="#PIDList.RecordCount#">
		<CFSET Out=Out & "kill -9 #PIDList.Name[CR]#" & Chr(10)>
		<CFFILE action="DELETE" file="#SaveDir#/pids/#PIDList.Name[CR]#">
	</CFLOOP>
	<CFSET Out=Out & "sleep 5" & Chr(10)>
	<CFFILE action="write" file="#SaveDir#/pid_cleanup.sh" mode="766" output="#Out#" addnewline="NO">
	<CFTRY>
		<CFEXECUTE name="#SaveDir#/pid_cleanup.sh" timeout="3060" />
	<CFCATCH Type="Any">
	</CFCATCH>
	</CFTRY>
	<CFOUTPUT>
	<script language="JavaScript">
	document.getElementById('Div_#PIDID#').style.display='none';
	</script>
	</CFOUTPUT>
	<CFFLUSH>
</CFIF>

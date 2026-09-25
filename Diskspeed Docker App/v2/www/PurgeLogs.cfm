<!--- Purge old log files --->
<CFDIRECTORY action="list" directory="/usr/local/tomcat/logs" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFIF Find(DateFormat(Now(),"yyyy-mm-dd"),Dir.Name[CR]) EQ 0>
		<CFTRY>
			<CFFILE action="DELETE" file="/usr/local/tomcat/logs/#Dir.Name[CR]#">
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>
	</CFIF>
</CFLOOP>

<CFDIRECTORY action="list" directory="/opt/lucee/server/lucee-server/context/logs" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFIF DateFormat(Dir.DateLastModified[CR],"yyyy-mm-dd") EQ DateFormat(Now(),"yyyy-mm-dd") AND Dir.Size[CR] GT 0>
		<CFTRY>
			<CFFILE action="WRITE" file="/opt/lucee/server/lucee-server/context/logs/#Dir.Name[CR]#" output="" addnewline="NO" mode="666">
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>
	</CFIF>
</CFLOOP>

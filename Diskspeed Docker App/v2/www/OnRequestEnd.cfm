<!--- Reset all file permissions --->
<CFTRY>
	<cfexecute name="/bin/chmod" arguments="766 /var/www/SetPerms.sh" timeout="10" />
	<cfexecute name="/var/www/SetPerms.sh" timeout="0" />
<CFCATCH Type="Any">
	<!--- Eat any errros --->
</CFCATCH>
</CFTRY>
<!--- Dump all variables --->
<CFSET StructClear(variables)>
<!--- Force Java Garbage Collection
<CFSET SysObj=CreateObject("java","java.lang.System")>
<CFSET SysObj.gc()>
<CFSET SysObj.runFinalization()>
 --->
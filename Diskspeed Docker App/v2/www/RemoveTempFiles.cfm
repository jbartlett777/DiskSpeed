<cflock name="TempFiles" type="exclusive" throwontimeout="false" timeout="90">
	<CFSET KeepTempFile="">
	<CFIF FileExists("/tmp/DiskSpeedTmp/TempFiles.txt")>
		<CFFILE action="read" file="/tmp/DiskSpeedTmp/TempFiles.txt" variable="Files">
		<CFSET Files=StripCR(Files)>
		<CFLOOP index="TempFN" list="#Files#" delimiters="#Chr(10)#">
			<CFIF FileExists("#TempFN#")>
				<CFTRY>
					<CFFILE action="DELETE" file="#TempFN#">
					<CFCATCH Type="Any">
						<!--- File is locked, persist it --->
						<CFSET KeepTempFile=ListAppend(KeepTempFile,TempFN,Chr(10))>
					</CFCATCH>
				</CFTRY>
			</CFIF>
		</CFLOOP>
		<CFIF KeepTempFile EQ "">
			<CFFILE action="delete" file="/tmp/DiskSpeedTmp/TempFiles.txt">
		<CFELSE>
			<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
				<CFFILE action="write" file="/tmp/DiskSpeedTmp/TempFiles.txt" output="#KeepTempFile#" addnewline="yes">
			</cflock>
		</CFIF>
	</CFIF>
</cflock>

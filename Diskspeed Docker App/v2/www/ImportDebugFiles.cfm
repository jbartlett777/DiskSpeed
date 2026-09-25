<CFDIRECTORY action="list" directory="/tmp/DiskSpeed/import" name="files" filter="*.gz">
<CFIF Files.RecordCount EQ 0>
	<cfexit method="exittemplate">
</CFIF>

<CFLOOP index="CR" from="1" to="#Files.RecordCount#">
	<CFSET Out="cd /tmp/DiskSpeed/import#Chr(10)#tar -xzf #Files.Name[CR]##Chr(10)#">
	<CFFILE action="write" file="/tmp/DiskSpeed/import/#CR#.sh" output="#Out#" addnewline="NO" mode="766">
	<cfexecute name="/tmp/DiskSpeed/import/#CR#.sh" timeout="300" />
</CFLOOP>

<CFDIRECTORY action="list" directory="/tmp/DiskSpeed/import/tmp/DiskSpeed/export/DiskSpeed/Instances" name="files">

<CFSET Out="">
<CFLOOP index="CR" from="1" to="#Files.RecordCount#">
	<CFIF DirectoryExists("/tmp/DiskSpeed/Instances/#Files.Name[CR]#")>
		<CFDIRECTORY action="delete" directory="/tmp/DiskSpeed/Instances/#Files.Name[CR]#" recurse="yes">
	</CFIF>
	<CFIF DirectoryExists("/tmp/DiskSpeedTmp/Instances/#Files.Name[CR]#")>
		<CFDIRECTORY action="delete" directory="/tmp/DiskSpeedTmp/Instances/#Files.Name[CR]#" recurse="yes">
	</CFIF>
	<CFSET Out=Out & "mv /tmp/DiskSpeed/import/tmp/DiskSpeed/export/DiskSpeed/Instances/#Files.Name[CR]# /tmp/DiskSpeed/Instances" & Chr(10)>
	<CFSET Out=Out & "mv /tmp/DiskSpeed/import/tmp/DiskSpeed/export/DiskSpeedTmp/Instances/#Files.Name[CR]# /tmp/DiskSpeedTmp/Instances" & Chr(10)>
</CFLOOP>
<CFSET Out=Out & "rm /tmp/DiskSpeed/import/*.gz" & Chr(10)>
<CFSET Out=Out & "rm /tmp/DiskSpeed/import/*.sh" & Chr(10)>
<CFFILE action="write" file="/tmp/DiskSpeed/import/mvinstances.sh" output="#Out#" addnewline="NO" mode="766">
<cfexecute name="/tmp/DiskSpeed/import/mvinstances.sh" timeout="300" />

<CFIF DirectoryExists("/tmp/DiskSpeed/import/tmp")>
	<CFDIRECTORY action="delete" directory="/tmp/DiskSpeed/import/tmp" recurse="yes">
</CFIF>

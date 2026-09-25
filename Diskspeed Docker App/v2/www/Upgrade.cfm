<CFIF Version GT 20221027 AND Version LT 20221031>
	<!--- Drive images were not properly saved to the driveinfo directories so they were not preserved on system scanning. Copy inuse image over --->
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFSET DirName=GetSaveDir(Key,PortNo)>
				<CFIF FileExists("#RootDir#/images/inuse/#CurrInstance#/#DirName#.png")>
					<CFFILE action="copy"
							source="#RootDir#/images/inuse/#CurrInstance#/#DirName#.png"
							destination="#PersistDir#/driveinfo/#DirName#/image.png"
							mode="666">
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFIF>

<CFIF FileExists("#PersistDir#/driveinfo/DriveBenchmarks.txt")>
	<CFFILE action="Delete" file="#PersistDir#/driveinfo/DriveBenchmarks.txt">
</CFIF>

<CFDIRECTORY action="list" directory="#PersistDir#" type="file" filter="*.txt,findports*.json,Drive*.xml" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="delete" file="#PersistDir#/#Dir.Name[CR]#">
</CFLOOP>

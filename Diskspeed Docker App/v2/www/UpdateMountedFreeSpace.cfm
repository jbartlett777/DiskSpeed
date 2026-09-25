<CFPARAM name="variables.CheckMountPoint" default="">
<CFSET CheckMountPointAvailSpace=0>

<!--- Fetch current free space on mounts --->
<cfexecute name="/bin/df" arguments="--block-size=1" variable="df"  timeout="90" />
<CFSET FreeSpace=QueryNew("FileSystem,TotalBytes,UsedBytes,AvailBytes,MountPoint","varchar,integer,integer,integer,varchar")>
<CFLOOP index="q1" from="2" to="#ListLen(df,Chr(10))#">
	<CFSET CurrLine=ListGetAt(df,q1,Chr(10))>
	<CFSET QueryAddRow(FreeSpace)>
	<CFSET QuerySetCell(FreeSpace,"FileSystem",ListGetAt(CurrLine,1," "))>
	<CFSET QuerySetCell(FreeSpace,"TotalBytes",ListGetAt(CurrLine,2," "))>
	<CFSET QuerySetCell(FreeSpace,"UsedBytes",ListGetAt(CurrLine,3," "))>
	<CFSET QuerySetCell(FreeSpace,"AvailBytes",ListGetAt(CurrLine,4," "))>
	<CFLOOP index="q2" from="1" to="5">
		<CFSET CurrLine=ListDeleteAt(CurrLine,1," ")>
	</CFLOOP>
	<CFSET QuerySetCell(FreeSpace,"MountPoint",CurrLine)>
</CFLOOP>

<!--- Check to see if the space changed --->
<CFSET UpdHW=0>
<CFLOOP index="Key2" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo2" from="1" to="#ArrayLen(HW[Key2].Ports)#">
		<CFIF HW[Key2].Ports[PortNo2].DriveID NEQ "">
			<CFLOOP index="z1" from="1" to="#ArrayLen(HW[Key2].Ports[PortNo2].Partitions.Partitions)#">
				<CFSET MP=HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].MountPoint>
				<CFIF MP NEQ "">
					<CFQUERY name="FS" dbtype="Query">
						SELECT *
						FROM FreeSpace
						WHERE MountPoint='#MP#'
					</CFQUERY>
					<CFIF FS.RecordCount GT 0>
						<CFPARAM name="HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].UsedSpace" default="0">
						<CFPARAM name="HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].AvailSpace" default="0">
						<CFIF HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].UsedSpace NEQ FS.UsedBytes>
							<CFSET UpdHW=1>
							<CFSET HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].UsedSpace=FS.UsedBytes>
						</CFIF>
						<CFIF HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].AvailSpace NEQ FS.AvailBytes>
							<CFSET UpdHW=1>
							<CFSET HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].AvailSpace=FS.AvailBytes>
						</CFIF>
					</CFIF>
					<CFIF MP EQ CheckMountPoint>
						<CFSET CheckMountPointAvailSpace=HW[Key2].Ports[PortNo2].Partitions.Partitions[z1].AvailSpace>
					</CFIF>
				</CFIF>
			</CFLOOP>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFIF UpdHW EQ 1>
	<CFSET json=SerializeJSON(HW)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
	</cflock>
</CFIF>

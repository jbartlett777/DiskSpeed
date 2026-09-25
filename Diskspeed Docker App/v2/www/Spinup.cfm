<!--- Randomly pick x blocks on the hard drives and read them --->

<CFPARAM name="variables.WakeupDrives" default="">
<CFPARAM name="variables.ValidateAwake" default="">
<CFIF StructKeyExists(variables,"ref") EQ "NO">
	<CFSET Ref=StructNew()>
	<CFSET Ref.DriveID=StructNew()>
	<CFSET tmp=StructNew()>
	<CFSET tmp.Configuration=StructNew()>
	<CFSET tmp.Configuration.BlockCount=100000>
	<!---<CFSET tmp.Configuration.LogicalSectorSize=512>--->
	<CFSET tmp.Configuration.RPM=0>
	<CFSET HW=StructNew()>
	<CFSET HW.A=StructNew()>
	<CFSET HW.A.Ports=ArrayNew(1)>
	<CFLOOP index="i" from="1" to="255">
		<CFSET DeviceID="sd" & FormatBaseN(i,26)>
		<CFIF FileExists("/sys/class/block/#DeviceID#/queue/physical_block_size")>
			<CFSET Ref.DriveID[DeviceID].Key="A">
			<CFSET Ref.DriveID[DeviceID].PortNo=i>
			<CFSET HW.A.Ports[i].Attrib=Duplicate(tmp)>
			<CFSET HW.A.Ports[i].Attrib.Configuration.LogicalSectorSize=StripCRLF(ReadFile("/sys/class/block/#DeviceID#/queue/physical_block_size","512"))>
		</CFIF>
	</CFLOOP>
	<CFLOOP index="i" from="1" to="9">
		<CFSET DeviceID="nvme#i-1#n1">
		<CFIF FileExists("/sys/class/block/#DeviceID#/queue/physical_block_size")>
			<CFSET Ref.DriveID[DeviceID].Key="A">
			<CFSET Ref.DriveID[DeviceID].PortNo=i>
			<CFSET HW.A.Ports[i].Attrib=Duplicate(tmp)>
			<CFSET HW.A.Ports[i].Attrib.Configuration.LogicalSectorSize=StripCRLF(ReadFile("/sys/class/block/#DeviceID#/queue/physical_block_size","512"))>
		</CFIF>
	</CFLOOP>
</CFIF>

<!---
<CFIF RunningUNRAID>
	<CFSET HostURL=ListFirst(CGI.HTTP_Host,":")>
	<CFIF Config.var.USE_SSL EQ "yes">
		<CFSET HostPort=config.var.PORTSSL>
	<CFELSE>
		<CFSET HostPort=config.var.PORT>
	</CFIF>
	<CFIF WakeupDrives EQ "">
		<CFIF Config.var.USE_SSL EQ "yes">
			<CFHTTP method="post" url="#HostURL#/webGui/include/ToggleState.php" port="#HostPort#" throwonerror="true">
				<CFHTTPPARAM type="formField" name="csrf" value="#config.var.csrf_token#">
				<CFHTTPPARAM type="formField" name="csrf_token" value="#config.var.csrf_token#">
				<CFHTTPPARAM type="formField" name="device" value="up">
				<CFHTTPPARAM type="formField" name="state" value="STARTED">
			</CFHTTP>
		<CFELSE>
			<CFHTTP method="post" url="#HostURL#/webGui/include/ToggleState.php" port="#HostPort#" throwonerror="true">
				<CFHTTPPARAM type="formField" name="csrf" value="#config.var.csrf_token#">
				<CFHTTPPARAM type="formField" name="csrf_token" value="#config.var.csrf_token#">
				<CFHTTPPARAM type="formField" name="device" value="up">
				<CFHTTPPARAM type="formField" name="state" value="STARTED">
			</CFHTTP>
		</CFIF>
	<CFELSE>
		<CFSET ThreadList="">
		<CFLOOP index="CurrDrive" list="#WakeupDrives#">
			<CFSET RefKey=Ref.DriveID[CurrDrive].Key>
			<CFSET RefPortNo=Ref.DriveID[CurrDrive].PortNo>
			<CFIF HW[RefKey].Ports[RefPortNo].UNRAIDSlot NEQ "">
				<CFSET ThreadList=ListAppend(ThreadList,CurrDrive)>
				<CFSET WakeupDrives=ListDeleteAt(WakeupDrives,ListFindNoCase(WakeupDrives,CurrDrive))>
				<CFSET DriveSlot=HW[RefKey].Ports[RefPortNo].UNRAIDSlotSrc>
				<CFTHREAD name="#CurrDrive#" action="run" DriveSlot="#DriveSlot#" HostURL="#HostURL#" HostPort="#HostPort#" csrf_token="#config.var.csrf_token#">
					<CFHTTP method="post" url="#HostURL#/webGui/include/ToggleState.php" port="#HostPort#" throwonerror="true">
						<CFHTTPPARAM type="formField" name="action" value="up">
						<CFHTTPPARAM type="formField" name="csrf" value="#csrf_token#">
						<CFHTTPPARAM type="formField" name="csrf_token" value="#csrf_token#">
						<CFHTTPPARAM type="formField" name="device" value="Device">
						<CFHTTPPARAM type="formField" name="name" value="#DriveSlot#">
						<CFHTTPPARAM type="formField" name="state" value="STARTED">
					</CFHTTP>
				</CFTHREAD>
			</CFIF>
		</CFLOOP>
		<CFTHREAD action="join" name="#ThreadList#" timeout="5000" />
	</CFIF>
</CFIF>
--->

<CFSET spinup="">
<CFSET spinup2="">
<CFPARAM name="variables.RefKey" default="">
<CFPARAM name="variables.RefPortNofKey" default="">
<!--- Identify all attached drives and get the information on them --->
<cfexecute name="/bin/ls" arguments="-l /sys/block" variable="BlockDevices"  timeout="90" />
<!--- <cfoutput><pre>#BlockDevices#</pre></cfoutput> --->
<CFLOOP index="i" from="2" to="#ListLen(BlockDevices,Chr(10))#">
	<CFSET CurrLine=ListGetAt(BlockDevices,i,Chr(10))>
	<CFIF FindNoCase("virtual",CurrLine) EQ 0>
		<CFSET DevicePath=ListLast(CurrLine,">")>
		<CFSET DevicePath="/sys/" & ListDeleteAt(DevicePath,1,"/")>
		<CFSET tmp=REMatchNoCase("[0-9a-z]{2,4}:[0-9a-z]{2}:[0-9a-z]{2}.[0-9a-z]",DevicePath)>
		<CFIF ArrayLen(tmp) GT 0>
			<!--- <CFSET Key=tmp[ArrayLen(tmp)]> --->
			<CFSET DeviceID=ListLast(DevicePath,"/")>
			<CFIF Left(DeviceID,2) NEQ "sr">
				<CFIF StructKeyExists(Ref.DriveID,DeviceID)>
					<CFSET RefKey=Ref.DriveID[DeviceID].Key>
					<CFSET RefPortNo=Ref.DriveID[DeviceID].PortNo>
				</CFIF>
				<CFIF WakeupDrives EQ "" OR ListFindNoCase(WakeupDrives,DeviceID)>
					<CFSET ReadSectors="">
					<CFIF RefKey EQ "" OR RefPortNo EQ "">
						<CFSET BlockCount=999999>
						<CFSET BlockSize=512>
					<CFELSE>
						<CFSET BlockCount=HW[RefKey].Ports[RefPortNo].Attrib.Configuration.BlockCount>
						<CFSET BlockSize=HW[RefKey].Ports[RefPortNo].Attrib.Configuration.LogicalSectorSize>
					</CFIF>
					<CFIF BlockCount GT 2147483640>
						<CFSET BlockCount=2147483640>
					</CFIF>
					<CFLOOP index="i" from="1" to="#SpinupBlockCount#">
						<CFSET ReadSectors=ListAppend(ReadSectors,RandRange(0,BlockCount))>
					</CFLOOP>
					<CFSET ReadSectors=ListSort(ReadSectors,"numeric")>
					<CFSET sh="">
					<CFIF RefKey EQ "" OR RefPortNo EQ "">
						<CFLOOP index="i" from="1" to="#SpinupBlockCount#">
							<CFSET sh=sh & "dd if=/dev/#DeviceID# of=/dev/null bs=#BlockSize# count=1 skip=#ListGetAt(ReadSectors,i)# iflag=direct " & Chr(10)>
						</CFLOOP>
					<CFELSE>
						<CFIF HW[RefKey].Ports[RefPortNo].Attrib.Configuration.RPM NEQ "Solid State Device">
							<CFLOOP index="i" from="1" to="#SpinupBlockCount#">
								<CFSET sh=sh & "dd if=/dev/#DeviceID# of=/dev/null bs=#BlockSize# count=1 skip=#ListGetAt(ReadSectors,i)# iflag=direct " & Chr(10)>
							</CFLOOP>
						</CFIF>
					</CFIF>
					<cflock name="FileWrite" type="exclusive" throwontimeout="true" timeout="10">
						<CFFILE action="write" file="/tmp/DiskSpeedTmp/spinup_#DeviceID#.sh" mode="766" output="#sh#" addnewline="NO">
					</cflock>
					<CFSET spinup=spinup & "/tmp/DiskSpeedTmp/spinup_#DeviceID#.sh &" & Chr(10)>
					<CFSET spinup2=spinup2 & "/tmp/DiskSpeedTmp/spinup_#DeviceID#.sh" & Chr(10)>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFPARAM name="variables.ErrorReason" default="">
<CFIF ValidateAwake EQ "">
	<CFIF WakeupDrives EQ "">
		<cflock name="FileWrite" type="exclusive" throwontimeout="true" timeout="10">
			<CFFILE action="write" file="/tmp/DiskSpeedTmp/spinup.sh" mode="766" output="#spinup#" addnewline="NO">
		</cflock>
		<CFTRY>
			<CFEXECUTE name="/tmp/DiskSpeedTmp/spinup.sh" timeout="0" />
		<CFCATCH Type="Any">
			<CFSET ErrorFlag=1>
			<CFSET ErrorReason=ListAppend(ErrorReason,"Drive Spinup 1","|")>
		</CFCATCH>
		</CFTRY>
	<CFELSE>
		<cflock name="FileWrite" type="exclusive" throwontimeout="true" timeout="10">
			<CFFILE action="write" file="/tmp/DiskSpeedTmp/spinup.sh" mode="766" output="#spinup2#" addnewline="NO">
		</cflock>
		<CFTRY>
			<CFEXECUTE name="/tmp/DiskSpeedTmp/spinup.sh" timeout="0" />
		<CFCATCH Type="Any">
			<CFSET ErrorFlag=1>
			<CFSET ErrorReason=ListAppend(ErrorReason,"Drive Spinup 2","|")>
		</CFCATCH>
		</CFTRY>
		<CFSET WakeupDrives="">
	</CFIF>
<CFELSE>
	<CFSET ValidateAwake="">
	<cflock name="FileWrite" type="exclusive" throwontimeout="true" timeout="10">
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/spinup.sh" mode="766" output="#spinup##spinup2#" addnewline="NO">
	</cflock>
	<CFTRY>
		<CFEXECUTE name="/tmp/DiskSpeedTmp/spinup.sh" timeout="0" />
	<CFCATCH Type="Any">
		<CFSET ErrorFlag=1>
		<CFSET ErrorReason=ListAppend(ErrorReason,"Drive Spinup 3","|")>
	</CFCATCH>
	</CFTRY>
</CFIF>

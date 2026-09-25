<CFIF URL.OptInPreview EQ "">
	<CFIF SMARTOptIn EQ "No">
		<CFOUTPUT>#TS()# SMART Data submission is disabled (<a href="ScanControllers.cfm?SmartOptInSel=Info">More Info</a>)<br></CFOUTPUT><CFFLUSH>
		<CFEXIT>
	</CFIF>
	<CFIF SMARTOptIn EQ "Delete">
		<CFOUTPUT>
		#TS()# SMART Data submission is disabled with deleting stored data (<a href="ScanControllers.cfm?SmartOptInSel=Info">More Info</a>)<br>
		#TS()# Gathering SMART information to identify data to request deletion...
		</CFOUTPUT>
	<CFELSE>
		<CFOUTPUT>
		#TS()# SMART Data submission is enabled (<a href="ScanControllers.cfm?SmartOptInSel=Info">More Info</a>)<br>
		#TS()# Gathering SMART information...
		</CFOUTPUT>
	</CFIF>
	<CFFLUSH>
<CFELSE>
	<!--- Load in HW, or create a stub if not found --->
	<CFIF FileExists("#PersistDir#/storage.json")>
		<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
		<CFSET HW=DeserializeJSON(json)>
	<CFELSE>
		<CFSET HW=StructNew()>
		<CFSET HW.Stub=StructNew()>
		<CFSET HW.Stub.Ports=ArrayNew()>
		<CFDIRECTORY action="list" directory="/sys/block" name="sysblock">
		<CFLOOP index="blockidx" from="1" to="#sysblock.recordcount#">
			<CFSET HW.Stub.Ports[blockidx]=StructNew()>
			<CFSET HW.Stub.Ports[blockidx].Attrib=StructNew()>
			<CFSET HW.Stub.Ports[blockidx].DriveID=sysblock.name[sysblock.RecordCount]>
			<CFSET HW.Stub.Ports[blockidx].Drive.Attrib.Vendor=ReadFile("/sys/block/" & sysblock.name[sysblock.RecordCount] & "/device/vendor")>
		</CFLOOP>
	</CFIF>
</CFIF>

<!--- Look for first non-nvme drive
<CFSET StartPort=1>
<CFSET OK=0>
<CFSET UseDrive="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET UseDrive=HW[Key].Ports[PortNo]>
		<CFIF UseDrive.DriveID NEQ "">
			<CFIF Left(UseDrive.DriveID,4) NEQ "nvme">
				<CFSET OK=1>
				<CFBREAK>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFIF OK EQ 1>
		<CFBREAK>
	</CFIF>
</CFLOOP>
 --->

<CFSET SMARTData=StructNew()>
<CFSET SMARTDataBlock=StructNew()>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET Drive=HW[Key].Ports[PortNo]>
		<CFIF Drive.DriveID NEQ "">
			<CFIF Left(Drive.DriveID,4) NEQ "nvme">
				<CFSET SMARTJson="">
				<CFSET DevPath="/dev/" & Drive.DriveID>
				<CFFILE action="write" file="#PersistDir#/#exe()#_smartctl_#Drive.DriveID#_exec.txt" output="/usr/sbin/smartctl --attributes -json #DevPath#" addnewline="NO" mode="666">
				<CFTRY>
					<CFEXECUTE name="/usr/sbin/smartctl" arguments="--all -json #DevPath#" variable="SMARTJson"></CFEXECUTE>
					<CFFILE action="write" file="#PersistDir#/#exe()#_smartctl_#Drive.DriveID#.txt" output="#SMARTJson#" addnewline="NO" mode="666">
				<CFCATCH Type="Any">
					<CFFILE action="write" file="#PersistDir#/#exe()#_smartctl_#Drive.DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
				</CFCATCH>
				</CFTRY>
				<CFIF SMARTJson NEQ "">
					<CFSET SMART=DeserializeJSON(SMARTJson)>
					<CFIF SMART.smartctl.exit_status EQ 0> <!--- Valid SMART --->
						<CFSET HashName=Drive.Attrib.Vendor>
						<CFLOOP index="Block" list="model_name,serial_number,firmware_version">
							<CFIF StructKeyExists(SMART,Block)>
								<CFSET HashName=ListAppend(HashName,SMART[Block],"|")>
							</CFIF>
						</CFLOOP>
						<CFIF HashName NEQ Drive.Attrib.Vendor> <!--- Only log ones that return smart info --->
							<CFSET ID="d" & LCase(Hash(HashName,"SHA"))>
							<CFSET SMARTDataBlock[ID]=Drive.DriveID>
							<CFSET SMARTData[ID]=StructNew("ordered")>
							<CFSET SMARTData[ID]["nvme"]=0>
							<CFIF StructKeyExists(Drive.Attrib,"CONFIGURATION")>
								<CFIF Drive.Attrib.Configuration.RPM EQ "Solid State Device">
									<CFSET SMARTData[ID]["ssd"]=1>
								<CFELSE>
									<CFSET SMARTData[ID]["ssd"]=0>
								</CFIF>
							</CFIF>
							<CFIF StructKeyExists(SMART,"model_name")>
								<CFSET SMARTData[ID]["model"]=SMART.model_name>
							</CFIF>
							<CFIF StructKeyExists(SMART,"firmware_version")>
								<CFSET SMARTData[ID]["rev"]=SMART.firmware_version>
							</CFIF>
							<CFIF StructKeyExists(SMART,"user_capacity")>
								<CFIF StructKeyExists(SMART.user_capacity,"bytes")>
									<CFSET SMARTData[ID]["bytes"]=SMART.user_capacity.bytes>
								</CFIF>
							</CFIF>
							<CFIF StructKeyExists(SMART,"ata_smart_attributes")>
								<CFSET SmartIdx2=0>
								<CFSET SMARTData[ID]["smart"]=ArrayNew(1)>
								<CFLOOP index="SmartIDX" from="1" to="#ArrayLen(SMART.ata_smart_attributes.table)#">
									<CFSET SmartIdx2=SmartIdx2 + 1>
									<CFSET SMARTData[ID].SMART[SmartIdx2]=StructNew("ordered")>
									<CFSET SMARTData[ID].SMART[SmartIdx2]["id"]=SMART.ata_smart_attributes.table[SmartIDX].id>
									<CFSET SMARTData[ID].SMART[SmartIdx2]["name"]=SMART.ata_smart_attributes.table[SmartIDX].name>
									<CFSET SMARTData[ID].SMART[SmartIdx2]["normalized"]=SMART.ata_smart_attributes.table[SmartIDX].value>
									<CFSET SMARTData[ID].SMART[SmartIdx2]["value"]=SMART.ata_smart_attributes.table[SmartIDX].raw.value>
									<CFSET SMARTData[ID].SMART[SmartIdx2]["string"]=SMART.ata_smart_attributes.table[SmartIDX].raw.string>
								</CFLOOP>
							</CFIF>
						</CFIF>
					</CFIF>
				</CFIF>
			<CFELSE>
				<CFSET SMARTJSON="">
				<CFSET DevPath="/dev/" & Drive.DriveID>
				<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smartlog_#Drive.DriveID#_exec.txt" output="/usr/sbin/nvme smart-log #DevPath# --output-format=json" addnewline="NO" mode="666">
				<CFTRY>
					<CFEXECUTE name="/usr/sbin/nvme" arguments="smart-log #DevPath# --output-format=json" variable="SMARTJson"></CFEXECUTE>
					<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smartlog_#Drive.DriveID#.txt" output="#SMARTJson#" addnewline="NO" mode="666">
				<CFCATCH Type="Any">
					<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smartlog_#Drive.DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
				</CFCATCH>
				</CFTRY>
				<CFIF SMARTJSON NEQ "">
					<CFSET SMART=DeserializeJSON(SMARTJson)>
					<CFSET HashName=HW[Key].Ports[PortNo].Attrib.Vendor & HW[Key].Ports[PortNo].Attrib.Model & HW[Key].Ports[PortNo].Attrib.Rev>
					<CFSET ID="d" & LCase(Hash(HashName,"SHA"))>
					<CFSET SMARTDataBlock[ID]=Drive.DriveID>
					<CFSET SMARTData[ID]=StructNew("ordered")>
					<CFSET SMARTData[ID].NVME=1>
					<CFSET SMARTData[ID].SSD=1>
					<CFSET SMARTData[ID].SMART=Duplicate(SMART)>
					<!--- Extract NVME info --->
					<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_list_#Drive.DriveID#_exec.txt" output="/usr/sbin/nvme list #DevPath# --output-format=json" addnewline="NO" mode="666">
					<CFTRY>
						<CFSET ResultFN="#PersistDir#/#exe()#_nvme_list_#Drive.DriveID#.bin">
						<CFEXECUTE name="/usr/sbin/nvme" arguments="list #DevPath# --output-format=json" variable="InfoJSON"></CFEXECUTE>
						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_list_#Drive.DriveID#.txt" output="#InfoJson#" addnewline="NO" mode="666">
						<CFSET Info=DeserializeJSON(InfoJson)>
						<CFIF StructKeyExists(Info,"Devices")>
							<CFIF IsArray(Info.Devices)>
								<CFIF StructKeyExists(Info.Devices[1],"Firmware")>
									<CFSET SMARTData[ID]["rev"]=Info.Devices[1].Firmware>
								</CFIF>
								<CFIF StructKeyExists(Info.Devices[1],"ModelNumber")>
									<CFSET SMARTData[ID]["model"]=Info.Devices[1].ModelNumber>
								</CFIF>
								<CFIF StructKeyExists(Info.Devices[1],"PhysicalSize")>
									<CFSET SMARTData[ID]["bytes"]=Info.Devices[1].PhysicalSize>
								</CFIF>
							</CFIF>
						</CFIF>
					<CFCATCH Type="Any">
						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_list_#Drive.DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
					</CFCATCH>
					</CFTRY>


					<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smart-log_#Drive.DriveID#_exec.txt" output="/usr/sbin/nvme smart-log #DevPath# --output-format=json" addnewline="NO" mode="666">
					<CFTRY>
						<CFSET ResultFN="#PersistDir#/#exe()#_nvme_smart-log_#Drive.DriveID#.bin">
						<CFEXECUTE name="/usr/sbin/nvme" arguments="smart-log #DevPath# --output-format=json" variable="InfoJSON"></CFEXECUTE>
						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smart-log_#Drive.DriveID#.txt" output="#InfoJson#" addnewline="NO" mode="666">
						<CFSET SMART=DeserializeJSON(InfoJson)>
						<CFLOOP index="Item" list="health">
							<CFIF StructKeyExists(SMART,Item)>
								<CFSET SMARTData[ID][Item]=SMART[Item]>
							</CFIF>
						</CFLOOP>
					<CFCATCH Type="Any">
						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_smart-log_#Drive.DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
					</CFCATCH>
					</CFTRY>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFSET SMARTJSON=SerializeJSON(SMARTData)>
<!---
<cfdump var=#smartdata# label="SMARTData">
<cfoutput>#SMARTJSON#</cfoutput>
--->

<CFIF SMARTOptIn EQ "Delete">
	<CFSET DelIDs=StructKeyList(SMARTData)>
	<CFSET h=LCase(Hash(DelIDs))>
	<CFHTTP url="#StrangeJourney#/diskspeed/smart.cfm?DelIDs=#EncodeForURL(DelIDs)#&h=#h#" method="GET"></CFHTTP>
	<CFFILE action="write" file="/tmp/DiskSpeed/SMARTOptIn.txt" output="No" addnewline="NO" mode="666">
	<CFOUTPUT>#CFHTTP.FileContent#<br></CFOUTPUT>
	<CFFLUSH>
<CFELSEIF SMARTOptIn EQ "Yes">
	<CFIF URL.OptInPreview EQ "">
		<!--- Save JSON --->
		<CFFILE action="write" file="/tmp/DiskSpeed/smartdata.json" output="#SMARTJson#" addnewline="NO">
		<!--- ZIP JSON --->
		<CFZip action="zip" file="/tmp/DiskSpeed/smartdata.zip">
			<CFZipParam source="/tmp/DiskSpeed/smartdata.json">
		</CFZip>
		<!--- Delete json file --->
		<CFTRY>
			<CFFILE action="delete" file="/tmp/DiskSpeed/smartdata.json">
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>

		<CFOUTPUT>
		done.<br>
		#TS()# Submitting SMART data...
		</CFOUTPUT>
		<CFFLUSH>

		<CFHTTP url="#StrangeJourney#/diskspeed/smart.cfm" method="POST">
			<CFHTTPPARAM type="file" name="ZipFile" file="/tmp/DiskSpeed/smartdata.zip">
		</CFHTTP>
		<CFIF Trim(CFHTTP.FileContent) NEQ "Ok">
			<CFOUTPUT>#CFHTTP.FileContent#<br></CFOUTPUT>
		<CFELSE>
			<CFOUTPUT>
			done, thank you.<br>
			</CFOUTPUT>
		</CFIF>
	</CFIF>
</CFIF>
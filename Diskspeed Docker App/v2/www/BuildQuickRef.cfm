<CFSET Ref=StructNew()>
<CFSET Ref.DriveID=StructNew()>
<CFSET Ref.Vendor=StructNew()>
<CFSET Ref.RAID=StructNew()>
<CFSET Ref.RAID.UUID=StructNew()>
<!--- <CFSET Ref.Tree=StructNew()> --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFSET Ref.DriveID[DriveID].Key=Key>
			<CFSET Ref.DriveID[DriveID].PortNo=PortNo>
			<CFSET Vendor=HW[Key].Ports[PortNo].Attrib.Vendor>
			<CFSET Model=HW[Key].Ports[PortNo].Attrib.Model>
			<CFIF StructKeyExists(Ref.Vendor,Vendor) EQ "NO">
				<CFSET Ref.Vendor[Vendor]=StructNew()>
			</CFIF>
			<CFIF StructKeyExists(Ref.Vendor[Vendor],Model) EQ "NO">
				<CFSET Ref.Vendor[Vendor][Model]="">
			</CFIF>
			<CFSET Ref.Vendor[Vendor][Model]=ListAppend(Ref.Vendor[Vendor][Model],"#Key#|#PortNo#")>
			<!--- Build RAID Members --->
			<CFIF StructKeyExists(HW[Key].Ports[PortNo],"Partitions")>
				<CFIF StructKeyExists(HW[Key].Ports[PortNo].Partitions,"Partitions")>
					<CFLOOP index="i" from="1" to="#ArrayLen(HW[Key].Ports[PortNo].Partitions.Partitions)#">
						<CFSET UUID=Trim(HW[Key].Ports[PortNo].Partitions.Partitions[i].UUID)>
						<CFSET MountPoint="">
						<CFIF StructKeyExists(HW[Key].Ports[PortNo].Partitions.Partitions[i],"MountPoint")>
							<CFSET MountPoint=HW[Key].Ports[PortNo].Partitions.Partitions[i].MountPoint>
						</CFIF>
						<CFIF UUID NEQ "" AND MountPoint NEQ "" AND HW[Key].Ports[PortNo].UNRAIDSlotSrc NEQ "parity">
							<CFIF StructKeyExists(Ref.RAID.UUID,UUID) EQ "NO">
								<CFSET Ref.RAID.UUID[UUID]="">
							</CFIF>
							<CFSET Ref.RAID.UUID[UUID]=ListAppend(Ref.RAID.UUID[UUID],DriveID)>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<!--- Remove UUID's with only one drive assigned --->
<CFLOOP index="UUID" list="#StructKeyList(Ref.RAID.UUID)#">
	<CFIF ListLen(Ref.RAID.UUID[UUID]) EQ 1>
		<CFSET StructDelete(Ref.RAID.UUID,UUID)>
	</CFIF>
</CFLOOP>


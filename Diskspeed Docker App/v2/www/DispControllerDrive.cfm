<CFSET i_icon=1>
<!--- <CFIF HW[Key].TotalDrives EQ 1 AND Key EQ "Unknown">
	<CFIF HW[Key].Ports[1].UNRAIDSlot NEQ "flash">
		<CFINCLUDE TEMPLATE="DispControllerInfo.cfm">
	</CFIF>
<CFELSE> --->
	<CFINCLUDE TEMPLATE="DispControllerInfo.cfm">
<!--- </CFIF> --->
<CFSET MaxDriveHeight=0>
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFIF HW[Key].Ports[PortNo].DriveID NEQ "" AND HW[Key].Ports[PortNo].CDROM EQ 0>
		<CFIF HW[Key].Ports[PortNo].Config.ImageHeight GT MaxDriveHeight>
			<CFSET MaxDriveHeight=HW[Key].Ports[PortNo].Config.ImageHeight>
		</CFIF>
	</CFIF>
</CFLOOP>
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFIF HW[Key].Ports[PortNo].DriveID NEQ "" AND HW[Key].NVMe EQ IncNVME>
		<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
			<!--- <CFSET ImgInfo=GetDriveCoverImage(HW[Key].Ports[PortNo])> --->
			<CFSET ThumbCSS=CSSName(HW[Key].Ports[PortNo].Config.SaveDir)>
			<CFSET ImageHeight=HW[Key].Ports[PortNo].Config.ImageHeight>
			<CFSET ImageWidth=HW[Key].Ports[PortNo].Config.ImageWidth>
			<CFSET ThumbCSSHN1="ThumbHeight1_" & ImageHeight>
			<CFSET ThumbCSSHN2="ThumbHeight2_" & ImageHeight>
			<CFSET DriveInfo="DispDrive.cfm?Drive=" & URLEncode("#Key#|#PortNo#")>
			<CFOUTPUT>
			<!---
			<div class="FloatLeft" style="width:133px;">
				<table border="0" cellpadding="0" cellspacing="0">
					<tr>
						<td class="Details ClipOverflow NOBR" width="#HW[Key].Ports[PortNo].Config.ImageWidth#">
							<CFIF Key EQ "Create" AND HW[Key].Ports[PortNo].Config.DriveEdited EQ 1><span class="Bold Red"></CFIF>
							<span class="Bold">
							#HW[Key].Ports[PortNo].DriveID#
							<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ "">
								(#HW[Key].Ports[PortNo].UNRAIDSlot#)
							</CFIF>
							</span><br>
							#HW[Key].Ports[PortNo].Attrib.Model#<br>
							#HW[Key].Ports[PortNo].Attrib.Serial#<CFIF HW[Key].Ports[PortNo].Attrib.Serial EQ "">&nbsp;</CFIF>
							<CFIF Key EQ "Create" AND HW[Key].Ports[PortNo].Config.DriveEdited EQ 1></span></CFIF>
						</td>
						<td rowspan="2">&nbsp;</td>
					</tr>
					<tr>
						<td class="#ThumbCSS#_td" id="#HW[Key].Ports[PortNo].DriveID#_image" onClick="location.href='#DriveInfo#'">
							<div class="#ThumbCSS#" id="#HW[Key].Ports[PortNo].DriveID#_text">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#</div>
						</td>
					</tr>
				</table>
			</div>
			--->
			<div class="FloatLeft" style="width:133px;height:247px;">
				<div class="DivTable">
					<div class="DivRow">
						<div class="DivCell Details ClipOverflow NOBR" style="max-width:128px;">
							<CFSET DriveLabel="">
							<CFIF Key EQ "Create" AND HW[Key].Ports[PortNo].Config.DriveEdited EQ 1><span class="Red"></CFIF>
							<CFIF Key NEQ "Unknown" AND HW[Key].NVMe EQ 0 AND HW[Key].USB EQ 0>
								<CFSET DriveLabel=DriveLabel & "Port #PortNo#: ">
							</CFIF>
							<CFIF HW[Key].USB EQ 1>
								<CFLOOP index="i" from="1" to="#ListLen(HW[Key].Ports[PortNo].DevicePath,"/")#">
									<CFIF Left(ListGetAt(HW[Key].Ports[PortNo].DevicePath,i,"/"),3) EQ "usb">
										<CFSET DriveLabel=DriveLabel & "Bus #Mid(ListGetAt(HW[Key].Ports[PortNo].DevicePath,i,'/'),4,99)#: ">
									</CFIF>
								</CFLOOP>
							</CFIF>
							<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ "">
								<CFSET DriveLabel=DriveLabel & "#HW[Key].Ports[PortNo].UNRAIDSlot# (#HW[Key].Ports[PortNo].DriveID#) ">
							<CFELSE>
								<CFSET DriveLabel=DriveLabel & "#HW[Key].Ports[PortNo].DriveID#">
							</CFIF>
							<span class="Bold" title="#EncodeForHTMLAttribute(DriveLabel)#">#EncodeForHTML(DriveLabel)#</span><br>
							#HW[Key].Ports[PortNo].Attrib.Model#<br>
							#HW[Key].Ports[PortNo].Attrib.Serial#<CFIF HW[Key].Ports[PortNo].Attrib.Serial EQ "">&nbsp;</CFIF>
							<CFIF Key EQ "Create" AND HW[Key].Ports[PortNo].Config.DriveEdited EQ 1></span></CFIF>
						</div>
						<div class="DivCell">&nbsp;</div>
					</div>
					<div class="DivRow">
						<div id="Drive_#HW[Key].Ports[PortNo].DriveID#" class="DivCell #ThumbCSS#_td Hand" style="width:128px;height:190px;" onClick="document.getElementById('RightFrame').src='#DriveInfo#';">
							<div class="#ThumbCSS#" id="#HW[Key].Ports[PortNo].DriveID#_text">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#</div>
						</div>
					</div>
				</div>
			</div>
			</CFOUTPUT>
		</CFIF>
	</CFIF>
</CFLOOP>



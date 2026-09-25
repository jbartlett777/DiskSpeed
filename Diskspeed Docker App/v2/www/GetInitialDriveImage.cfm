<CFPARAM name="RefreshDrive" default="0">
<CFPARAM name="NoFlush" default="0">

<CFOUTPUT>#TS()# Fetching drive images<br></CFOUTPUT><CFIF NOT NoFlush><CFFLUSH></CFIF>

<!---
<CFSET SendVendor="">
<CFSET SendModel="">
<CFSET Processed="">
--->

<CFSET FetchDrives="">
<CFLOOP index="CurrItem" list="#NeedImage#" delimiters="~">
	<CFSET Key=ListFirst(CurrItem,"|")>
	<CFSET PortNo=ListLast(CurrItem,"|")>
	<CFSET Drive=HW[Key].Ports[PortNo]>
	<CFSET FetchDrives=ListAppend(FetchDrives,"#Drive.DriveID#~#Drive.Attrib.Vendor#~#Drive.Attrib.Model#")>
</CFLOOP>
<CFSET FetchDrives=Replace(FetchDrives,"~~","~Unknown~","ALL")>
<!--- <CFSET h=LCase(Hash(SendVendor & "|" & SendModel & "|1"))> --->
<CFSET DriveURL="#StrangeJourney#/diskspeed/FetchDriveImages2.cfm?FetchDrives=" & URLEncodedFormat(FetchDrives) & "&UserID=" & URLEncodedFormat(UserID) & "&Version=" & Version>
<CFFILE action="write" file="#PersistDir#/DriveImageHTTPRequest.txt" output="#DriveURL#" addnewline="NO" mode="666">
<CFHTTP URL="#DriveURL#" />
<!--- <CFOUTPUT>URL: #DriveURL#</CFOUTPUT><cfdump var=#cfhttp#> --->
<CFSET json=SerializeJSON(CFHTTP)>
<CFFILE action="write" file="#PersistDir#/DriveImageHTTPResult.json" output="#json#" addnewline="NO" mode="666">
<CFIF CFHTTP.Status_Code EQ 200>
	<CFIF StripCRLF(Trim(CFHTTP.FileContent)) EQ "">
		<CFSET Info=ArrayNew(1)>
	<CFELSE>
		<CFSET Info=DeserializeJSON(CFHTTP.FileContent)>
	</CFIF>
	<!--- <CFSET Image=BinaryDecode(Info[1].Image,"Base64")>
	<CFFILE action="write" file="#RootDir#/images/inuse/#Drive.Config.SaveDir#.png" output="#Image#" mode="666">
	<cfoutput><img src="/images/inuse/#Drive.Config.SaveDir#.png?x=#RandRange(0,99999999)#"></cfoutput> --->
	<CFSET Reported="">
	<CFLOOP index="CurrDriveID" list="#StructKeyList(Info.DriveData)#">
		<CFIF StructKeyExists(Ref.DriveID,CurrDriveID)>
			<CFSET CurrKey=Ref.DriveID[CurrDriveID].Key>
			<CFSET CurrPortNo=Ref.DriveID[CurrDriveID].PortNo>
			<CFSET DriveDir=GetSaveDir(CurrKey,CurrPortNo)>
			<CFSET ReportID=HW[CurrKey].Ports[CurrPortNo].Attrib.Vendor & " " & HW[CurrKey].Ports[CurrPortNo].Attrib.Model>
			<CFIF Info.DriveData[CurrDriveID].Found EQ 0>
				<CFIF ListFindNoCase(Reported,ReportID) EQ "NO">
					<CFSET Reported=ListAppend(Reported,ReportID)>
					<CFOUTPUT>#TS()# Drive image NOT found for #ReportID#<br></CFOUTPUT>
				</CFIF>
				<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#PersistDir#/driveinfo/#DriveDir#/image.png">
				<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#RootDir#/images/inuse/#CurrInstance#/#DriveDir#.png">
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.DefaultImage=1>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.FetchInfo=1>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.ImageWidth=128>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.ImageHeight=172>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.Random=GetTickCount()>
			<CFELSE>
				<CFIF ListFindNoCase(Reported,ReportID) EQ "NO">
					<CFSET Reported=ListAppend(Reported,ReportID)>
					<CFOUTPUT>#TS()# Drive image found for #ReportID#<br></CFOUTPUT>
				</CFIF>
				<CFSET DriveImage=BinaryDecode(Info.ImageData[Info.DriveData[CurrDriveID].Image],"Base64")>
				<CFFILE action="write" file="#PersistDir#/driveinfo/#DriveDir#/image.png" output="#DriveImage#" addnewline="NO">
				<CFFILE action="write" file="#RootDir#/images/inuse/#CurrInstance#/#DriveDir#.png" output="#DriveImage#" addnewline="NO">
				<CFSET ImgInfo=ImageInfo(DriveImage)>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.DefaultImage=0>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.FetchInfo=0>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.ImageWidth=ImgInfo.Width>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.ImageHeight=ImgInfo.Height>
				<CFSET HW[CurrKey].Ports[CurrPortNo].Config.Random=GetTickCount()>
			</CFIF>
			<CFSET HW[CurrKey].Ports[CurrPortNo].Attrib.Vendor=Info.DriveData[CurrDriveID].Vendor>
			<CFLOOP index="CurrObj" list="#StructKeyList(Info.DriveData[CurrDriveID])#">
				<CFIF ListFindNoCase("Vendor,Model,Image,Found",CurrObj) EQ 0>
					<CFSET HW[CurrKey].Ports[CurrPortNo].Config[CurrObj]=Info.DriveData[CurrDriveID][CurrObj]>
				</CFIF>
			</CFLOOP>
			<CFSET JSON=SerializeJSON(HW[CurrKey].Ports[CurrPortNo].Config)>
			<CFFILE action="write" file="#PersistDir#/driveinfo/#DriveDir#/config.json" output="#JSON#" addnewline="NO" mode="666">
		</CFIF>






		<!--- <CFOUTPUT><img src="data:image/png;base64, #Info[i].Image#" /><br></CFOUTPUT> --->

		<!---
		<CFSET UpdateList=Ref.Vendor[Info[i].Vendor][Info[i].Model]>

		<CFLOOP index="CurrDrive" list="#UpdateList#">
			<CFSET Key=ListFirst(CurrDrive,"|")>
			<CFSET PortNo=ListLast(CurrDrive,"|")>
			<CFIF HW[Key].Ports[PortNo].Config.DefaultImage EQ 1>
				<CFSET DriveDir=HW[Key].Ports[PortNo].Config.SaveDir>
				<CFIF Info[i].Found EQ 0>
					<!--- <cfoutput>default #PersistDir#/driveinfo/#DriveDir#/image.png<br></cfoutput> --->
					<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#PersistDir#/driveinfo/#DriveDir#/image.png">
					<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#RootDir#/images/inuse/#CurrInstance#/#HW[Key].Ports[PortNo].Config.SaveDir#.png">
					<!--- <CFSET HW[Key].Ports[PortNo].Config.FetchInfo=0> --->
					<CFOUTPUT>#TS()# Drive image NOT found for #HW[Key].Ports[PortNo].Attrib.Vendor# #HW[Key].Ports[PortNo].Attrib.Model#<br></CFOUTPUT>
				<CFELSE>
					<!--- <cfoutput>imported #PersistDir#/driveinfo/#DriveDir#/image.png<br>#RootDir#/images/inuse/#Drive.Config.SaveDir#.png<hr></cfoutput> --->
					<!--- <CFFILE action="write" file="#PersistDir#/driveinfo/#DriveDir#/image.png" output="#Image#" mode="666">
					<CFFILE action="write" file="#RootDir#/images/inuse/#CurrInstance#/#HW[Key].Ports[PortNo].Config.SaveDir#.png" output="#Image#" mode="666"> --->
					<CFSET Image=BinaryDecode(Info[i].Image,"Base64")>
					<CFSET ImgInfo=ImageInfo(Image)>
					<CFSET OutFN="#PersistDir#/driveinfo/#DriveDir#/image.png">
					<CFSET ImageWrite(Image,OutFN,1)>
					<CFSET OutFN="#RootDir#/images/inuse/#CurrInstance#/#HW[Key].Ports[PortNo].Config.SaveDir#.png">
					<CFSET ImageWrite(Image,OutFN,1)>
					<CFLOOP index="CurrKey" list="#StructKeyList(Info[i])#">
						<CFIF ListFindNoCase("vendor,model,image",CurrKey) EQ 0>
							<CFSET HW[Key].Ports[PortNo].Config[CurrKey]=Info[i][CurrKey]>
						</CFIF>
					</CFLOOP>
					<CFSET HW[Key].Ports[PortNo].Config.DefaultImage=0>
					<CFSET HW[Key].Ports[PortNo].Config.FetchInfo=0>
					<CFSET HW[Key].Ports[PortNo].Config.ImageWidth=ImgInfo.Width>
					<CFSET HW[Key].Ports[PortNo].Config.ImageHeight=ImgInfo.Height>
					<CFSET HW[Key].Ports[PortNo].Config.Random=GetTickCount()>
					<!---
					<CFIF Info[i].NewVendor NEQ "">
						<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=Info[i].NewVendor>
					</CFIF>
					--->
					<CFSET JSON=SerializeJSON(HW[Key].Ports[PortNo].Config)>
					<CFFILE action="write" file="#PersistDir#/driveinfo/#DriveDir#/config.json" output="#JSON#" addnewline="NO" mode="666">
					<CFIF ListFindNoCase(Reported,"#HW[Key].Ports[PortNo].Attrib.Vendor#|#HW[Key].Ports[PortNo].Attrib.Model#") EQ 0>
						<CFSET Reported=ListAppend(Reported,"#HW[Key].Ports[PortNo].Attrib.Vendor#|#HW[Key].Ports[PortNo].Attrib.Model#")>
						<CFOUTPUT>#TS()# Drive image found for #HW[Key].Ports[PortNo].Attrib.Vendor# #HW[Key].Ports[PortNo].Attrib.Model#<br></CFOUTPUT>
					</CFIF>
				</CFIF>
			</CFIF>
			<!--- <cfdump var=#info[i]#><cfoutput><hr></cfoutput> --->
		</CFLOOP>
		--->
	</CFLOOP>
	<!--- <cfdump var=#info# --->
<CFELSE>
	<CFOUTPUT>#TS()# There was an error fetching the initial drive images<br></CFOUTPUT><CFIF NOT NoFlush><CFFLUSH></CFIF>
	<CFIF DiskSpeedDeveloper>
		<CFOUTPUT>URL: #DriveURL#<br></CFOUTPUT>
	</CFIF>
</CFIF>
<!--- <cfdump var=#cfhttp#>
<cfdump var=#Drive#> --->

<!---
<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
 --->

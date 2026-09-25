<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>
<CFFILE action="read" file="#PersistDir#/miscref.json" variable="json">
<CFSET MiscRef=DeserializeJSON(json)>

<CFSET Out=StructNew()>
<CFIF ListLen(Config.var.RegTo,".") EQ 4>
	<CFSET Config.var.RegTo=MiscRef.MBSerial>
</CFIF>
<CFSET Out.UserIDSHA=Hash(Hash(Config.var.RegTo,"SHA") & Hash(Config.var.RegGUID,"SHA"),"SHA")>
<CFSET Out.Version=Version>
<CFSET Out.DriveData=ArrayNew()>
<CFSET Out.BenchmarkData=ArrayNew()>
<CFSET DriveList="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF HW[Key].USB EQ 0>
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF Hw[Key].Ports[PortNo].CDROM EQ 0>
					<CFSET DriveDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>
					<CFIF FileExists("#DriveDir#/nosubmit.txt") EQ "NO">
						<CFSET Drive=Duplicate(HW[Key].Ports[PortNo].Attrib)>
						<CFIF HW[Key].Ports[PortNo].HDDBFound EQ 0>
							<CFSET tmp=Drive.Vendor & "|" & Drive.Model & "|" & Drive.Rev>
							<CFIF ListFindNoCase(DriveList,tmp) EQ 0>
								<CFSET DriveList=ListAppend(DriveList,tmp)>
								<CFSET i=ArrayLen(Out.DriveData) + 1>
								<CFSET Out.DriveData[i]=StructNew()>
								<CFSET Out.DriveData[i].Vendor=Drive.Vendor>
								<CFSET Out.DriveData[i].Model=Drive.Model>
								<CFSET Out.DriveData[i].Revision=Drive.Rev>
								<CFSET Out.DriveData[i].Capacity=Drive.Size.Bytes>
								<CFSET Out.DriveData[i].SSD=0>
								<CFSET Out.DriveData[i].RPM="">
								<CFIF Drive.Configuration.RPM EQ "Solid State Device">
									<CFSET Out.DriveData[i].SSD=1>
								<CFELSE>
									<CFSET Out.DriveData[i].RPM=Drive.Configuration.RPM>
								</CFIF>
								<CFSET Out.DriveData[i].SignalingSpeed=Drive.Configuration.SignalingSpeedDisp>
								<CFSET Out.DriveData[i].LogicalSectorSize=Drive.Configuration.LogicalSectorSize>
								<CFSET Out.DriveData[i].PhysicalSectorSize=Drive.Configuration.SectorSize>
								<CFSET Out.DriveData[i].MultipleSectorTransfer=Drive.Configuration.MultipleSectorTransfer.Max>
							</CFIF>
						</CFIF>
						<CFSET BenchDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir & "/benchmark">
						<CFDIRECTORY action="list" directory="#BenchDir#" name="BenchData" type="Dir">
						<CFLOOP index="BenchIdx" from="1" to="#BenchData.RecordCount#">
							<CFIF FileExists("#BenchDir#/#BenchData.Name[BenchIdx]#/submitted.txt") EQ "NO">
								<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/speed.json" variable="json">
								<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/datestamp.txt" variable="BenchDateStamp">
								<CFSET Latency="0|0|0">
								<CFIF FileExists("#BenchDir#/#BenchData.Name[BenchIdx]#/latency.txt")>
									<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/latency.txt" variable="Latency">
								</CFIF>
								<CFSET SpeedData=DeserializeJSON(json,false)>
								<CFSET SpeedDataOut=ArrayNew(2)>
								<CFLOOP index="SpeedIdx" from="1" to="#SpeedData.RecordCount#">
									<CFSET SpeedDataOut[SpeedIdx][1]=SpeedData.Spot[SpeedIdx]>
									<CFSET SpeedDataOut[SpeedIdx][2]=SpeedData.Speed[SpeedIdx]>
								</CFLOOP>
								<CFSET i=ArrayLen(Out.BenchmarkData) + 1>
								<CFSET Out.BenchmarkData[i]=StructNew()>
								<CFSET Out.BenchmarkData[i].Vendor=Drive.Vendor>
								<CFSET Out.BenchmarkData[i].dir="#BenchDir#/#BenchData.Name[BenchIdx]#">
								<CFSET Out.BenchmarkData[i].Model=Drive.Model>
								<CFSET Out.BenchmarkData[i].Revision=Drive.Rev>
								<CFSET Out.BenchmarkData[i].DateStamp=BenchDateStamp>
								<CFSET Out.BenchmarkData[i].RandomSeek=ListFirst(Latency,"|")>
								<CFSET Out.BenchmarkData[i].SequentialSeek=ListGetAt(Latency,2,"|")>
								<CFSET Out.BenchmarkData[i].DriveLatency=ListLast(Latency,"|")>
								<CFSET Out.BenchmarkData[i].SerialHash=Hash36("#Drive.Vendor#|#Drive.Model#|#Drive.Serial#")>
								<CFSET Out.BenchmarkData[i].Benchmark=Duplicate(SpeedDataOut)>
								<CFIF FileExists("#BenchDir#/#BenchData.Name[BenchIdx]#/SSDReadSpeed.txt")>
									<CFTRY>
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/SSDReadSpeedList.txt" variable="SSDReadSpeedList">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/SSDWriteSpeedList.txt" variable="SSDWriteSpeedList">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/SSDTestFileSize.txt" variable="SSDTestFileSize">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/SSDReadSpeed.txt" variable="SSDReadSpeed">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/SSDWriteSpeed.txt" variable="SSDWriteSpeed">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/BouncyDrive.txt" variable="BouncyDrive">
										<CFFILE action="read" file="#BenchDir#/#BenchData.Name[BenchIdx]#/CacheDetected.txt" variable="CacheDetected">
										<CFSET Out.BenchmarkData[i].SSDReadSpeedList=SSDReadSpeedList>
										<CFSET Out.BenchmarkData[i].SSDWriteSpeedList=SSDWriteSpeedList>
										<CFSET Out.BenchmarkData[i].SSDReadSpeed=SSDReadSpeed>
										<CFSET Out.BenchmarkData[i].SSDWriteSpeed=SSDWriteSpeed>
										<CFSET Out.BenchmarkData[i].TestFileSize=SSDTestFileSize>
										<CFSET Out.BenchmarkData[i].BouncyDrive=BouncyDrive>
										<CFSET Out.BenchmarkData[i].CacheDetected=CacheDetected>
									<CFCATCH Type="Any">
									</CFCATCH>
									</CFTRY>
								</CFIF>
							</CFIF>
						</CFLOOP>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFIF>
</CFLOOP>
<CFSET json=SerializeJSON(Out)>
<CFSET H=LCase(Hash(json & URLEncodedFormat(json)))>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<style type="text/css">
td {font-family:Arial, Helvetica, sans-serif;}
</style>
<!-- #RepeatString("x",1024)# -->
</CFOUTPUT>

<CFHTTP method="POST" URL="#StrangeJourney#/diskspeed/SubmitDriveData.cfm" timeout="30">
	<CFHTTPPARAM type="formfield" name="DriveData" value="#json#">
	<CFHTTPPARAM type="formfield" name="h" value="#H#">
</CFHTTP>

<CFIF CFHTTP.FileContent NEQ "OK">
	<CFOUTPUT>
	There was an error processing the data. Error Data:<hr>#CFHTTP.FileContent#
	<CFIF DiskSpeedDeveloper>
		URL: #StrangeJourney#/diskspeed/SubmitDriveData.cfm<br>
		<cfdump var=#json#>
	</CFIF>
	</CFOUTPUT>
	<CFFLUSH>
<CFELSE>
	<CFOUTPUT>
	<br><br><br><br>
	<center>
	<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
			<td align="center">The information has been successfully uploaded. Thank you for your contributions!</td>
		</tr>
	</table>
	</center>
	<br><br><br><br>
	</CFOUTPUT>
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
					<CFSET Drive=Duplicate(HW[Key].Ports[PortNo].Attrib)>
					<CFIF HW[Key].Ports[PortNo].HDDBFound EQ 0>
						<CFSET HW[Key].Ports[PortNo].HDDBFound=1>
					</CFIF>
					<CFSET BenchDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir & "/benchmark">
					<CFDIRECTORY action="list" directory="#BenchDir#" name="BenchData" type="Dir">
					<CFLOOP index="BenchIdx" from="1" to="#BenchData.RecordCount#">
						<CFIF FileExists("#BenchDir#/#BenchData.Name[BenchIdx]#/submitted.txt") EQ "NO">
							<CFFILE action="write" file="#BenchDir#/#BenchData.Name[BenchIdx]#/submitted.txt" output="" addnewline="NO" mode="666">
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
	<CFSET json=SerializeJSON(HW)>
	<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
</CFIF>

<CFOUTPUT>
</body>
</html>
</CFOUTPUT>

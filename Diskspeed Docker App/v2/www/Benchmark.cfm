<cfsetting enablecfoutputonly="true" requesttimeout="9999">

<CFPARAM name="FORM.SyncDrives" default="N">
<CFPARAM name="FORM.FineTune" default="N">
<CFPARAM name="FORM.Go" default="">
<CFPARAM name="FORM.Cancel" default="">
<CFPARAM name="FORM.Seconds" default="15">
<CFPARAM name="FORM.SkipSSD" default="0">
<CFPARAM name="FORM.DetectSSDBuffer" default="0">
<CFPARAM name="FORM.DisableSpeedGap" default="0">
<CFPARAM name="FORM.SSDBenchmarkCPUs" default="0">
<CFPARAM name="URL.Restart" default="">
<CFPARAM name="URL.Sec" default="15">
<CFPARAM name="FORM.TestFileSizeOverride" default="0">
<CFPARAM name="FORM.SSDBenchmarkTestFiles" default="#SSDBenchmarkTestFiles_Default#">
<!---<CFPARAM name="FORM.SSDBenchmarkTestFileSize" default="2147483648">--->
<CFPARAM name="FORM.MinSSDSpaceFree" default="#MinSSDSpaceFreeDefault#">
<CFPARAM name="FORM.WaitBeforeRead" default="5">
<!---
<CFIF Val(FORM.SSDBenchmarkTestFiles) LT 1 OR Val(FORM.SSDBenchmarkTestFiles) GT SSDBenchmarkTestFiles_Max>
	<CFSET FORM.SSDBenchmarkTestFiles=SSDBenchmarkTestFiles_Default>
</CFIF>
--->
<CFIF IsNumeric(FORM.TestFileSizeOverride) EQ "No">
	<CFSET FORM.TestFileSizeOverride=0>
</CFIF>
<CFIF IsNumeric(FORM.SSDBenchmarkCPUs) EQ "NO">
	<CFSET FORM.SSDBenchmarkCPUs=4>
</CFIF>
<!---
<CFIF ListFindNoCase("1073741824,2147483648,4294967296,5368709120",FORM.SSDBenchmarkTestFileSize) EQ 0>
	<CFSET FORM.SSDBenchmarkTestFileSize=2147483648>
</CFIF>
--->

<CFLOOP index="Key" list="SkipSSD,DetectSSDBuffer,DisableSpeedGap">
	<CFIF ListFind("0,1",FORM[Key]) EQ 0>
		<CFSET FORM[Key]=0>
	</CFIF>
</CFLOOP>

<CFSET URL.Sec=Val(URL.Sec)>
<CFIF URL.Sec EQ 0>
	<CFLOCATION URL="index.cfm" addtoken="NO">
</CFIF>

<CFIF FORM.Cancel EQ "Cancel">
	<CFLOCATION URL="index.cfm" addtoken="NO">
</CFIF>

<CFIF FileExists("/tmp/DiskSpeedTmp/Kill.txt")>
	<CFFILE action="delete" file="/tmp/DiskSpeedTmp/Kill.txt">
</CFIF>

<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFINCLUDE template="UpdateMountedFreeSpace.cfm">
<CFELSE>
	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>

<CFSET DeleteTestFiles()>

<CFIF StructKeyExists(HW,"Unknown")>
	<CFLOOP index="PortNo" from="#ArrayLen(HW.Unknown.Ports)#" to="1" step="-1">
		<CFIF HW.Unknown.Ports[PortNo].DriveID NEQ "">
			<CFIF StructKeyExists(HW.Unknown.Ports[PortNo],"UNRAIDSlot")>
				<CFIF HW.Unknown.Ports[PortNo].UNRAIDSlot EQ "flash">
					<CFSET ArrayDeleteAt(HW.Unknown.Ports,PortNo)>
					<CFSET HW.Unknown.TotalDrives=HW.Unknown.TotalDrives - 1>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFIF HW.Unknown.TotalDrives EQ 0>
		<CFSET StructDelete(HW,"Unknown")>
		<CFINCLUDE TEMPLATE="BuildQuickRef.cfm">
	</CFIF>
</CFIF>

<CFSET SSDList="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"RPM")>
				<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device">
					<CFSET SSDList=ListAppend(SSDList,DriveID)>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Build a list of all SSD pool drives except for the first drive --->
<CFSET PoolSSDChildren="">
<CFLOOP index="UUID" list="#StructKeyList(Ref.RAID.UUID)#">
	<CFLOOP index="i" from="#ListLen(Ref.RAID.UUID[UUID])#" to="1" step="-1">
		<CFSET DriveID=ListGetAt(Ref.RAID.UUID[UUID],i)>
		<CFSET Key=Ref.DriveID[DriveID].Key>
		<CFSET PortNo=Ref.DriveID[DriveID].PortNo>
		<!--- Check to see if the drive is the first in the pool (no number at end of unraid slot src), and leave in if so --->
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"IsSSD")>
			<CFIF HW[Key].Ports[PortNo].IsSSD EQ 1 AND IsNumeric(Right(HW[Key].Ports[PortNo].UnraidSlotSrc,1))>
				<CFSET PoolSSDChildren=ListAppend(PoolSSDChildren,DriveID)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<CFSET Removeable="">
<CFSET CheckDrives=StructNew()>
<CFSET CheckDrives.Parity="">
<CFSET CheckDrives.Cache="">
<CFSET CheckDrives.Disk="">
<CFSET CheckDrives.Other="">
<CFLOOP index="LabelSort" list="Parity,Disk,Cache,Other">
	<CFSET CheckLabel=LabelSort>
	<CFIF CheckLabel EQ "Other">
		<CFSET CheckLabel="">
	</CFIF>
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
			<CFIF DriveID NEQ "">
				<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
					<!---<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 1>
						<CFSET Removeable=ListAppend(Removeable,DriveID)>
					<CFELSE>--->
						<CFSET Label=HW[Key].Ports[PortNo].UNRAIDSlot>
						<CFIF FindNoCase(CheckLabel,Label) GT 0 OR (CheckLabel EQ "" AND (Label EQ "" OR (FindNoCase("Parity",Label) EQ 0 AND FindNoCase("Cache",Label) EQ 0 AND FindNoCase("Disk",Label) EQ 0)))>
							<CFIF Label NEQ "">
								<CFSET Label=LJustify(Label,20)>
							</CFIF>
							<CFSET CheckDrives[LabelSort]=ListAppend(CheckDrives[LabelSort],"#Label#|#DriveID#")>
						</CFIF>
					<!---</CFIF>--->
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFLOOP>
<CFSET CheckDrives=ListSort(CheckDrives.Parity,"text") & "," & ListSort(CheckDrives.Disk,"text") & "," & ListSort(CheckDrives.Cache,"text") & "," & ListSort(CheckDrives.Other,"text")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<title>DiskSpeed</title>
<script type="text/javascript" src="/includes/jquery-3.2.1.min.js"></script>
<script type="text/javascript" src="#Highcharts#/highcharts.js"></script>
<script type="text/javascript" src="#Highcharts#/highcharts-more.js"></script>
<script type="text/javascript" src="/includes/jquery.fancybox.min.js"></script>
<link rel="stylesheet" type="text/css" href="/includes/jquery.fancybox.min.css">
<style type="text/css">
body {font-family:Arial, Helvetica, sans-serif;}
td {font-family:Arial, Helvetica, sans-serif;}
.Bold {font-weight:bold;}
.Size14 {font-size:14px;}
.Size24 {font-size:24px;}
.Red {color:red;}
.Grey {color:##909090;}
.Hand {cursor:pointer;}
.Hidden {display:none !important;}
.NOBR {white-space:nowrap;}
.Columns {-moz-column-width:160px;-webkit-column-width:160px;column-width:160px;}
.FloatLeft {float:left;}
.BR {clear:left;}
.Container {min-width:300px;max-width:400px;height:200px;margin:0 auto;}
.DivTable {display:table;}
.DivRow {display:table-row;}
.DivCell {display:table-cell;}
</style>
</head>
<body>
<div onClick="location.href='index.cfm'" class="Hand">
</CFOUTPUT>
<CFINCLUDE template="DispHeader.cfm">
<CFOUTPUT>
</div>
</CFOUTPUT>

<CFDIRECTORY action="list" type="file" directory="/tmp/DiskSpeedTmp" filter="benchmark_*.txt" name="BenchCheck">
<CFIF BenchCheck.RecordCount GT 0>
		<CFLOOP index="CR" from="1" to="#BenchCheck.RecordCount#">
			<CFFILE action="Delete" file="/tmp/DiskSpeedTmp/#BenchCheck.Name[CR]#">
		</CFLOOP>
		<CFLOCATION URL="Benchmark.cfm" addtoken="NO">
</CFIF>

<CFIF FORM.GO NEQ "Start Drive Benchmarks">
	<CFOUTPUT>
	<div style="width:800px;">
	This benchmark utility will read hard drives at given locations across the drive and display the average read speed of each location
	on a graph. Comparing benchmarks over time can give a hint to the general health of a drive and the graph should have a gradual
	declining curve from left to right. If there is a flat area on the left before falling, your drive likely exceeds the capabilities
	of the controller it is connected to.<br>
	<br>
	For more information how the benchmarks work, view the <span class="Size14 Red Hand Underline" data-fancybox data-type="iframe" data-src="/BenchmarkHelp.cfm?x=#GetTickCount()#">FAQ</span>
	</div>
	<br>
	<CFSET Per="1,2,5,10,20,25">
	<CFSET PerCnt="101,51,21,11,6,5">
	<CFSET PerTime="27 minutes,13.6 minutes,5.6 minutes,3 minutes,96 seconds,80 seconds">
	<script language="JavaScript">
	var SSDBenchmarkEnable=1;
	function SetMinutes()
	{
		var t=['#Replace(PerTime,",","','","ALL")#'];
		document.getElementById('timetorun').innerHTML=t[document.getElementById('Per').selectedIndex];
	}
	</script>
	<table border="0" cellpadding="0" cellspacing="0" style="width:800px;">
		<tr>
			<td>
				<form method="POST" onSubmit="return Validations()">
				<input type="Hidden" name="Seconds" value="#URL.Sec#">
				<div class="FloatLeft">Hard Drive tests drives every
				<select name="Per" id="Per" size="1" onChange="SetMinutes()">
				<CFLOOP index="Per" list="1,2,5,10,20,25">
					<CFIF Per EQ 10>
						<option value="#Per#" SELECTED>#Per#%</option>
					<CFELSE>
						<option value="#Per#">#Per#%</option>
					</CFIF>
				</CFLOOP>
				</select> of the hard drive - Each drive will take&nbsp;</div><div class="FloatLeft" id="timetorun">&nbsp;</div><div class="FloatLeft">&nbsp;to scan.<br><br></div><div class="BR">

				<div class="FloatLeft" id="SSDTests">
					<!---
					There are #DockerInfo.CPU.Assigned# CPU's <CFIF DockerInfo.CPU.Total NEQ DockerInfo.CPU.Assigned>(out of #DockerInfo.CPU.Total#)</CFIF>
					available to split the write load to saturate the buffer. Use
					<CFSET SelectCPU=DockerInfo.CPU.Assigned - 4>
					<CFIF SelectCPU LT 1>
						<CFSET SelectCPU=1>
					</CFIF>
					<select name="SSDBenchmarkCPUs" id="SSDBenchmarkCPUs" size="1" onChange="EvalSSD()">
						<CFLOOP index="q" from="1" to="#DockerInfo.CPU.Assigned#">
							<CFIF q/8 NEQ Int(q/8)> <!--- FIO will seg fault if NumJobs divisable by 8 --->
								<CFIF q EQ SelectCPU>
									<option value="#q#" SELECTED>#q#</option>
								<CFELSE>
									<option value="#q#">#q#</option>
								</CFIF>
							</CFIF>
						</CFLOOP>
					</select> CPU's, each of which will create 4 files that combined will equal
					--->
					<!---
					 Solid State Drive Tests will use a max of 
					<select name="SSDBenchmarkTestFiles" id="SSDBenchmarkTestFiles" size="1" onChange="EvalSSD()">
						<CFLOOP index="i" from="1" to="#SSDBenchmarkTestFiles_Max#">
							<CFIF i EQ SSDBenchmarkTestFiles_Default>
								<option value="#i#" SELECTED="SELECTED">#i#</option>
							<CFELSE>
								<option value="#i#">#i#</option>
							</CFIF>
						</CFLOOP>
					</select>
					--->
					Solid State Drive tests will create 4 files that combined will equal
					<select name="TestFileSizeOverride" id="TestFileSizeOverride" size="1" OnChange="ToggleSSD()">
						<option value="0" SELECTED="SELECTED">1 GB for SATA and 4 GB for NVMe drives.</option>
						<option value="#Int(OneGB * 0.5)#">#Int(OneGB * 0.5)# (for really slow SSD's)</option>
						<option value="#Int(OneGB * 0.75)#">#Int(OneGB * 0.75)# (for slow SSD's)</option>
						<CFLOOP index="q" from="1" to="20">
							<option value="#q * OneGB#">#KBytes(q * OneGB)#</option>
						</CFLOOP>
					</select>
					The test will continue until drive cache is exhausted (write speed drops) or 
					<select name="MinSSDSpaceFree" id="SSDBenchmarkTestFileSize" size="1" onChange="EvalSSD()">
					<CFLOOP index="i" list="1,5,10,25,100,500,1000">
						<CFSET FileSize=Val(i) * OneGB>
						<CFIF i EQ MinSSDSpaceFreeDefault>
							<option value="#FileSize#" SELECTED="SELECTED">#KBytes(FileSize)#</option>
						<CFELSE>
							<option value="#FileSize#">#KBytes(FileSize)#</option>
						</CFIF>
					</CFLOOP>
					</select>
					of space is left available if the max number of files hasn't been reached yet. Wait for
					<select name="WaitBeforeRead" size="1" id="WaitBeforeRead">
						<CFLOOP index="i" from="0" to="30">
							<option value="#i#"<CFIF i EQ 10> SELECTED="SELECTED"</CFIF>>#i#</option>
						</CFLOOP>
					</select>
					seconds before starting the read portion of the test to catch drives that hide their write buffer.
					<br><br></div>
				</div>
				<div class="BR"></div>
				<CFIF PoolSSDChildren NEQ "">
					SSD Pool drives detected. Only the first drive in the pool will be selectable.<br><br>
				</CFIF>

				<input type="Checkbox" name="Drives" id="AllDrivesCheckbox" value="All" CHECKED onChange="ToggleAllDrives()"> <label for="AllDrivesCheckbox">Check all drives</label><br>
				<fieldset id="AllDriveList" style="display:none;">
					<legend>Select Drives to Optimize</legend>
					<div class="Columns NOBR">
					<CFSET ValJS="">
					<CFSET SkipLabel2="">
					<CFLOOP index="CurrDrive" list="#CheckDrives#">
						<CFSET tmpDriveID=Trim(ListLast(CurrDrive,"|"))>
						<CFSET tmpLabel=Trim(ListFirst(CurrDrive,"|"))>
						<CFSET ValJS=ValJS & "if (document.getElementById('Check_#tmpDriveID#').checked == true) DrivesSelected++;" & Chr(10)>
						<div class="FloatLeft">
						<table border="0" cellpadding="0" cellspacing="0">
							<tr>
								<td class="NOBR">
									<input type="Checkbox" name="Drives" id="Check_#tmpDriveID#" value="#tmpDriveID#" onChange="ToggleDrive(this)">
									<label for="Check_#tmpDriveID#">
										<span id="Check_#tmpDriveID#_Label_1">#tmpDriveID#</span>
										<CFIF tmpLabel NEQ tmpDriveID>
											<span class="Black" id="Check_#tmpDriveID#_Label_2"> (#tmpLabel#)</span>
										<CFELSE>
											<CFSET SkipLabel2=ListAppend(SkipLabel2,tmpDriveID)>
										</CFIF>
									</label>
								</td>
							</tr>
						</table>
						</div>
						<div class="BR"></div>
					</CFLOOP>
					</div>
				</fieldset>
				<CFIF SSDList NEQ "">
					<input type="Checkbox" name="SkipSSD" id="SkipSSD" value="1" onChange="ToggleSSD()" CHECKED> <label for="SkipSSD">Skip SSD's</label><br>
				</CFIF>
				<input type="Checkbox" name="DisableSpeedGap" id="DisableSpeedGap" value="1"> <label for="DisableSpeedGap">Disable Speed Gap detection (if you frequently get this on a drive)</label><br><br>
				<input type="submit" name="go" value="Start Drive Benchmarks">
				</form>
			</td>
		</tr>
		<tr>
			<td valign="bottom">
				<form action="index.cfm">
				<input type="submit" value="Cancel">
				</form>
			</td>
		</tr>
		<tr id="SSDSizeWarn" style="display:none">
			<td>
				<span class="Red">
				<br>
				Note: Changing the size of the files may scew your score results. Smaller files may complete faster but they must be large enough to take longer than a second to
				create each set of files or the result will likely report faster scores than realistic scores. Larger files will take much longer to complete and will add to the
				device wear level but will give more steady numbers as long as your file size is smaller than the drive's cache amount.
				</span>
			</td>
		</tr>
	</table>
	<br>
	<script language="JavaScript">
	<CFLOOP index="CurrDrive" list="#CheckDrives#">
		<CFSET CurrDriveID=ListLast(CurrDrive,"|")>
		<CFIF ListFindNoCase(SSDList,CurrDriveID)>
			<CFSET RefKey=Ref.DriveID[CurrDriveID].Key>
			<CFSET RefPortNo=Ref.DriveID[CurrDriveID].PortNo>
			<CFSET SSDFreeSpace=0>

			<CFSET Drive=HW[RefKey].Ports[RefPortNo]>
			<CFSET Benchmarkable=0>
			<CFSET DriveUUID="FOOBAR">
			<CFIF Drive.Attrib.Configuration.RPM NEQ "Solid State Device">
				<CFSET Benchmarkable=1>
			<CFELSE>
				<CFLOOP index="i" from="1" to="#ArrayLen(Drive.Partitions.Partitions)#">
					<CFIF Drive.Partitions.Partitions[i].MountPoint NEQ "">
						<CFIF DirectoryExists(Drive.Partitions.Partitions[i].MountPoint)>
							<CFIF StructKeyExists(Drive.Partitions.Partitions[i],"UsedSpace")>
								<CFIF Drive.Partitions.Partitions[i].Size - Drive.Partitions.Partitions[i].UsedSpace GTE 26843545600>
									<CFSET Benchmarkable=1>
									<CFSET SSDFreeSpace=Drive.Partitions.Partitions[i].Size>
									<CFSET DriveUUID=Drive.Partitions.Partitions[i].UUID>
									<CFIF Trim(DriveUUID) EQ "">
										<CFSET DriveUUID=Drive.DriveID>
									</CFIF>
									<CFBREAK>
								</CFIF>
							</CFIF>
						</CFIF>
					</CFIF>
				</CFLOOP>
				<CFIF Benchmarkable>
					<!--- Check if partition UUID's exist on other drives --->
					<CFIF DriveUUID NEQ "FOOBAR">
						<CFIF StructKeyExists(Ref.RAID.UUID,DriveUUID) AND ListFindNoCase(PoolSSDChildren,CurrDriveID)>
							<CFSET Benchmarkable=0>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFIF>
			var Drive_#CurrDriveID#_SSD=#Benchmarkable#;
			var Drive_#CurrDriveID#_FreeSpace=#SSDFreeSpace#;
			<CFIF Left(CurrDriveID,4) EQ "nvme">
				var Drive_#CurrDriveID#_IsNVMe=1;
			<CFELSE>
				var Drive_#CurrDriveID#_IsNVMe=0;
			</CFIF>
		<CFELSE>
			var Drive_#CurrDriveID#_SSD=0;
			var Drive_#CurrDriveID#_IsNVMe=0;
		</CFIF>
	</CFLOOP>

	SetMinutes();
	<CFIF SSDList NEQ "">
		function EvalSSD()
		{
			if (document.getElementById('SkipSSD').checked == true) return;

			//var TestFileTotalSize=Number(document.getElementById('SSDBenchmarkTestFiles').value) * Number(document.getElementById('SSDBenchmarkTestFileSize').value);
			var TestFileTotalSize=Number(document.getElementById('SSDBenchmarkTestFileSize').value);
			//var TestFileTotalSizeGB=TestFileTotalSize / 1073741824;
			//document.getElementById('SSDMinSpace').innerHTML=(TestFileTotalSizeGB + 5).toString() + ' GB';
			<CFLOOP index="CurrDrive" list="#SSDList#">
				<CFIF ListFindNoCase(Removeable,Currdrive) EQ 0>
					if (Drive_#CurrDrive#_SSD == 0)
					{
						document.getElementById('Check_#CurrDrive#').disabled=true;
					} else {
						if (Drive_#CurrDrive#_FreeSpace < TestFileTotalSize)
						{
							document.getElementById('Check_#CurrDrive#').disabled=true;
							document.getElementById('Check_#CurrDrive#_Label_1').style.color='##ff0000';
						<CFIF ListFindNoCase(SkipLabel2,CurrDrive) EQ 0>
							document.getElementById('Check_#CurrDrive#_Label_2').style.color='##ff0000';
						</CFIF>
						} else {
							document.getElementById('Check_#CurrDrive#').disabled=false;
							document.getElementById('Check_#CurrDrive#_Label_1').style.color='##000000';
							<CFIF ListFindNoCase(SkipLabel2,CurrDrive) EQ 0>
								document.getElementById('Check_#CurrDrive#_Label_2').style.color='##000000';
							</CFIF>
						}
					}
				</CFIF>
			</CFLOOP>
		}
		var PoolSSDChildren='#PoolSSDChildren#';
		function ToggleSSD()
		{
			disablestate=false;
			labelcolor='##000000';
			if (document.getElementById('SkipSSD').checked == true)
			{
				disablestate=true;
				labelcolor='##909090';
				document.getElementById('SSDSizeWarn').style.display='none';
			} else {
				if (document.getElementById('TestFileSizeOverride').value != '0') {
					document.getElementById('SSDSizeWarn').style.display='block';
				} else {
					document.getElementById('SSDSizeWarn').style.display='none';
				}
			}
			//document.getElementById('SSDBenchmarkTestFiles').disabled=disablestate;
			//document.getElementById('SSDBenchmarkCPUs').disabled=disablestate;
			document.getElementById('SSDBenchmarkTestFileSize').disabled=disablestate;
			document.getElementById('TestFileSizeOverride').disabled=disablestate;
			document.getElementById('WaitBeforeRead').disabled=disablestate;
			document.getElementById('SSDTests').style.color=labelcolor;
			
			<CFLOOP index="CurrDrive" list="#SSDList#">
				<CFIF ListFindNoCase(Removeable,Currdrive) EQ 0>
					if (document.getElementById('Check_#CurrDrive#').checked == true)
					{
						document.getElementById('Check_#CurrDrive#').checked=false;
						DrivesSelected--;
					}
					document.getElementById('Check_#CurrDrive#').disabled=disablestate;
					document.getElementById('Check_#CurrDrive#_Label_1').style.color=labelcolor;
					<CFIF ListFindNoCase(SkipLabel2,CurrDrive) EQ 0>
						document.getElementById('Check_#CurrDrive#_Label_2').style.color=labelcolor;
					</CFIF>
				</CFIF>
			</CFLOOP>
			EvalSSD();
		}
		ToggleSSD();
	</CFIF>
	DrivesSelected=0;
	function ToggleAllDrives()
	{
		if (document.getElementById('AllDrivesCheckbox').checked == true)
		{
			document.getElementById('AllDriveList').style.display='none';
			DrivesSelected++;
		} else {
			document.getElementById('AllDriveList').style.display='block';
			DrivesSelected--;
		}
	}
	function ToggleDrive(ckbox)
	{
		if (ckbox.checked == true)
		{
			DrivesSelected++;
		} else {
			DrivesSelected--;
		}
	}
	function Validations()
	{
		DrivesSelected=0;
		if (document.getElementById('AllDrivesCheckbox').checked == true) DrivesSelected++;
		#ValJS#
		if (DrivesSelected == 0)
		{
			alert('You must select at least one drive to test');
			return false;
		}
		return true;
	}
	ToggleAllDrives();
	</script>
	</body>
	</html>
	</CFOUTPUT>
	<CFABORT>
</CFIF>






<CFIF DebugFlag><CFOUTPUT><br></CFOUTPUT></CFIF>
<CFINCLUDE TEMPLATE="SetKillFlag.cfm">

<CFSET Test=StructNew()>
<CFSET TestDrives="">
<CFSET SSDDrives="">
<CFSET MaxBytes=0>
<CFSET SSDMaxBytes=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<!---<CFIF DebugFlag><CFOUTPUT><br>Processing controller #Key#<br></CFOUTPUT></CFIF>--->
	<CFSET ScanDrives="">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<!---<CFIF DebugFlag><CFOUTPUT>Processing #DriveID#<br></CFOUTPUT></CFIF>--->
			<CFIF ListFindNoCase(FORM.Drives,"All") OR ListFindNoCase(FORM.Drives,DriveID)>
				<!---<CFIF DebugFlag><CFOUTPUT>ListFindNoCase(FORM.Drives,"All") [#ListFindNoCase(FORM.Drives,"All")#] OR ListFindNoCase(FORM.Drives,DriveID) [#ListFindNoCase(FORM.Drives,DriveID)#]<br></CFOUTPUT></CFIF>--->
				<CFSET IsSSD=0>
				<!---<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 0>--->
					<!---<CFIF DebugFlag><CFOUTPUT>Device is flagged as not USB<br></CFOUTPUT></CFIF>--->
					<CFIF StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"RPM")>
						<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device" OR Left(DriveID,4) EQ "nvme">
							<!---<CFIF DebugFlag><CFOUTPUT>HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device" [#HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device"#] OR Left(DriveID,4) EQ "nvme" [#Left(DriveID,4) EQ "nvme"#]<br>Device is a SSD<br></CFOUTPUT></CFIF>--->
							<CFSET IsSSD=1>
						</CFIF>
					</CFIF>
					<CFIF FORM.SkipSSD EQ 0>
						<CFIF IsSSD EQ 1 AND ListFindNoCase(PoolSSDChildren,DriveID) EQ 0>
							<!---<CFIF DebugFlag><CFOUTPUT>Drive added to SSD scan list<br></CFOUTPUT></CFIF>--->
							<CFSET SSDDrives=ListPrepend(SSDDrives,DriveID)>
							<CFSET ScanDrives=ListPrepend(ScanDrives,DriveID)>
							<CFSET TestDrives=ListPrepend(TestDrives,DriveID)>
						<CFELSE>
							<!---<CFIF DebugFlag><CFOUTPUT>Drive added to spinner scan list 1<br></CFOUTPUT></CFIF>--->
							<CFSET ScanDrives=ListAppend(ScanDrives,DriveID)>
							<CFSET TestDrives=ListAppend(TestDrives,DriveID)>
						</CFIF>
					<CFELSE>
						<CFIF IsSSD EQ 0>
							<!---<CFIF DebugFlag><CFOUTPUT>Drive added to spinner scan list 2<br></CFOUTPUT></CFIF>--->
							<CFSET ScanDrives=ListAppend(ScanDrives,DriveID)>
							<CFSET TestDrives=ListAppend(TestDrives,DriveID)>
						</CFIF>
					</CFIF>
				<!---<CFELSE>
					<!---<CFIF DebugFlag><CFOUTPUT>Device flagged as USB, skipped<br></CFOUTPUT></CFIF>--->
				</CFIF>--->
				<CFIF IsSSD>
					<CFIF HW[Key].Ports[PortNo].Attrib.Size.Bytes GT SSDMaxBytes>
						<CFSET SSDMaxBytes=HW[Key].Ports[PortNo].Attrib.Size.Bytes>
					</CFIF>
				<CFELSE>
					<CFIF HW[Key].Ports[PortNo].Attrib.Size.Bytes GT MaxBytes>
						<CFSET MaxBytes=HW[Key].Ports[PortNo].Attrib.Size.Bytes>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<!--- Remove solid state pool devices from scan list  --->
	<CFLOOP index="UUID" list="#StructKeyList(Ref.RAID.UUID)#">
		<CFLOOP index="i" from="#ListLen(Ref.RAID.UUID[UUID])#" to="1" step="-1">
			<CFSET DriveID=ListGetAt(Ref.RAID.UUID[UUID],i)>
			<!--- Check to see if the drive is the first in the pool (no number at end of unraid slot src), and leave in if so --->
			<CFIF IsNumeric(Right(HW[Ref.DriveID[DriveID].Key].Ports[Ref.DriveID[DriveID].PortNo].UnraidSlotSrc,1))>
				<CFSET Loc=ListFindNoCase(SSDDrives,ListGetAt(Ref.RAID.UUID[UUID],i))>
				<CFIF Loc GT 0>
					<CFSET SSDDrives=ListDeleteAt(SSDDrives,Loc)>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
	<CFIF ScanDrives NEQ "">
		<CFSET Test[Key]=ScanDrives>
	</CFIF>
</CFLOOP>
<CFSET TestDrives=ListSort(TestDrives,"text")>

<CFSET SeriesOut1="">
<CFSET SeriesOut2="">
<CFSET SeriesList1="">
<CFSET SeriesList2="">
<CFSET DriveSlot=StructNew()>
<CFSET i=0>
<CFSET ColorIndex=-1>
<CFLOOP index="CurrDrive" list="#CheckDrives#">
	<CFSET Label=Trim(ListFirst(CurrDrive,"|"))>
	<CFSET DriveID=ListLast(CurrDrive,"|")>
	<CFIF ListFindNoCase(TestDrives,DriveID)>
		<CFSET DriveSlot[DriveID]=i>
		<CFIF Label EQ DriveID>
			<CFSET Series=DriveID>
		<CFELSE>
			<CFSET Series="#Label# (#DriveID#)">
		</CFIF>
		<CFSET ColorIndex=ColorIndex + 1>
		<CFIF ColorIndex GTE 10>
			<CFSET ColorIndex=0>
		</CFIF>
		<CFIF ListFind(SSDDrives,DriveID) EQ 0>
			<CFSET CurrSeries1="{name: '#Series#', type: 'spline', color: Highcharts.getOptions().colors[#ColorIndex#], data: []}">
			<CFSET CurrSeries2="{name: '#Series#', type: 'spline', color: Highcharts.getOptions().colors[#ColorIndex#], data: []}">
			<CFSET SeriesList1=ListAppend(SeriesList1,Series,"|")>
			<CFSET SeriesList2=ListAppend(SeriesList2,Series,"|")>
		<CFELSE>
			<CFSET CurrSeries1="{name: '#Series# (r)', type: 'boxplot', yAxis: 1, color: Highcharts.getOptions().colors[#ColorIndex#], data: []}," &
							   "{name: '#Series# (w)', type: 'boxplot', yAxis: 1, color: Highcharts.getOptions().colors[#ColorIndex#], data: []}">
			<CFSET CurrSeries2="">
			<CFSET SeriesList1=ListAppend(SeriesList1,"#Series# (r)","|")>
			<CFSET SeriesList1=ListAppend(SeriesList1,"#Series# (w)","|")>
		</CFIF>
		<CFIF SeriesOut1 NEQ "">
			<CFSET SeriesOut1=SeriesOut1 & "," & Chr(10)>
		</CFIF>
		<CFSET SeriesOut1=SeriesOut1 & CurrSeries1>
		<CFIF SeriesOut2 NEQ "" AND CurrSeries2 NEQ "">
			<CFSET SeriesOut2=SeriesOut2 & "," & Chr(10)>
		</CFIF>
		<CFSET SeriesOut2=SeriesOut2 & CurrSeries2>
		<CFIF ListFind(SSDDrives,DriveID) EQ 0>
			<CFSET i=i+1>
		<CFELSE>
			<CFSET i=i+2>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFOUTPUT>
<div id="graph1" style="min-width: 800px; max-width: 1600px; height: 500px; margin: 0 auto;"></div>
<table border="0" cellpadding="0" cellspacing="0"><tr><td>Click on a drive label to hide or show it</td><td onClick="ShowDebug()">.</td></tr></table>

<script type="text/javascript">
var Chart1=Highcharts.chart('graph1', {
	title: {
		text: 'Drive Size'
	},
<CFIF SSDMaxBytes EQ 0>
	xAxis: {
		title: {
			text: 'Size'
		},
		min: 0,
		max: #MaxBytes#
	},
	yAxis: {
		title: {
			text: 'Speed'
		},
		min: 0
	},
<CFELSE>
		xAxis: [{
			title: {
				text: 'Size'
			},
			min: 0,
			max: #MaxBytes#
		},{
			title: {
				text: 'Size'
			},
			visible: false
		}],
		yAxis: [{
			title: {
				text: 'Speed'
			},
			min: 0
		},{
			title: {
				text: 'SSD Speed'
			},
			min: 0,
			opposite: true
		}],
</CFIF>
    plotOptions: {
        series: {
            marker: {
                enabled: false
            },
            animation: true,
            connectNulls: true
        },
		boxplot: {
			lineWidth: 2,
			medianWidth: 8,
			stemWidth: 0,
			whiskerWidth: 0,
			findNearestPointBy: 'xy'
		}
	},
    tooltip: {
		formatter: function() {
			var outx=0;
			var outy=0;
			var outmin=0;
			var outmax=0;
			var outmed=0;
			if (this.point.low > 0) {
				outmin=Math.round(this.point.low / 1000000);
				outmax=Math.round(this.y / 1000000);
				outmed=Math.round(this.point.median / 1000000);
				if (outmin == outmax && outmin == outmed) return this.series.name + ': ' + outmed + ' MB/sec';
				return this.series.name + ': Range: ' + outmin + ' - ' + outmax + ' MB/sec, Avg ' + outmed + ' MB/sec';
			} else {
				outx=Math.round(this.x / 1000000000);
				outy=(this.y / 1000000).toFixed(2);
				return this.series.name + ': ' + outy + ' MB/sec at ' + outx + ' GB';
			}
		}
    },
	legend: {
		enabled: true
	},
	credits: {
		enabled: false
	},
	lang: {
		nodata: 'No data to display yet'
	},
	series: [#SeriesOut1#]
});
/*
var Chart2=Highcharts.chart('graph2', {
	title: {
		text: 'By Drive Percentage'
	},
	xAxis: {
		title: {
			text: 'Percent'
		},
		min: 0,
		max: 100
	},
	yAxis: {
		title: {
			text: 'Speed'
		},
		min: 0
	},
    plotOptions: {
        series: {
            marker: {
                enabled: false
            },
            animation: true,
            connectNulls: true
        }
    },
    tooltip: {
        formatter: function() {
        	var outy=(this.y / 1000000).toFixed(2);
            return this.series.name + ': ' + outy + 'MB/sec at ' + this.x + '%';
        }
    },
	legend: {
		enabled: true
	},
	credits: {
		enabled: false
	},
	lang: {
		nodata: 'No data to display yet'
	},
	series: [#SeriesOut2#]
});
*/
var TestsRunning=#ListLen(StructKeyList(Test))#;
function SubTest()
{
	TestsRunning--;
}
function CheckForFinished()
{
	if (TestsRunning == 0)
	{
		//document.getElementById('abortbutton').style.display='none';
		//document.getElementById('continuebutton').style.display='block';
		document.getElementById('AbortButton1').style.display='none';
		document.getElementById('AbortButton2').style.display='none';
		document.getElementById('AbortButton3').style.display='block';
	} else {
		setTimeout(CheckForFinished,100);
	}
}
CheckForFinished();
</script>
</CFOUTPUT>

<CFSET Slots="">
<CFLOOP index="DriveID" list="#StructKeyList(DriveSlot)#">
	<CFSET Slots=ListAppend(Slots,"#DriveID#-" & DriveSlot[DriveID])>
</CFLOOP>


<CFOUTPUT>
<button id="AbortButton1" onClick="document.getElementById('abortbuttonframe').src='/isolated/CheckDriveOptAbort.cfm';document.getElementById('AbortButton1').style.display='none';document.getElementById('AbortButton2').style.display='block'">Abort Benchmarking</button>
<button id="AbortButton2" style="display:none" disabled="disabled" disabled="true">Aborting Benchmark...</button>
<button id="AbortButton3" style="display:none" onClick="window.location.href='index.cfm'">Continue</button>
<iframe id="abortbuttonframe" style="display:none"></iframe>
<span id="BandwidthCapped">&nbsp;</span><br>
<span id="SpeedGapDetected" style="display:none">
<span class="Red">Notice:</span> A "Speed Gap" was detected on a drive which means the amount of data read from one second to the next had a speed difference in<br>
excess of a given amount and was retested.<br>
This is typically a sign of activity on the drive from another process but may be due to a troublesome spot and the drive's internal error correction working.<br>
If you keep getting Speed Gap warnings on a drive, abort the benchmark and set the checkbox for "Disable Speed Gap detection" on the benchmark section.<br>
</span>
<script language="JavaScript">
CappedDrives='';
function BandwidthCap(txt)
{
	if (CappedDrives == '')
	{
		CappedDrives=txt;
		document.getElementById('BandwidthCapped').innerHTML='Bandwidth was capped on drive ' + CappedDrives;
	} else {
		CappedDrives=CappedDrives + ', ' + txt;
		document.getElementById('BandwidthCapped').innerHTML='Bandwidth was capped on the following drives: ' + CappedDrives;
	}
	return true;
}
</script>
<form action="index.cfm" method="get"><input type="submit" value="Continue" style="display:none" id="continuebutton"></form>

<CFSET DebugIDs="">
<CFSET SSDSPot=1>
<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="10">
	<!--- Indicate which SSD benchmark can run --->
	<CFSET Application.SSDSlot=1>
</cflock>
<CFLOOP index="Key" list="#StructKeyList(Test)#">
	<CFSET ControllerID="controller_" & Replace(Replace(Key,":","_","ALL"),".","_","ALL")>
	<CFSET DebugIDs=ListAppend(DebugIDs,"#ControllerID#_debug")>
	<CFSET URLVal="Controller=#URLEncodedFormat(Key)#&Drives=#Test[Key]#&Per=#Form.Per#&scanid=#GetTickCount()#&Seconds=#URL.Sec#&Slots=#Slots#&DisableSpeedGap=#FORM.DisableSpeedGap#&SSDSpot=#SSDSpot#&&MaxBytes=#MaxBytes#&MinSSDSpaceFree=#FORM.MinSSDSpaceFree#&DetectSSDBuffer=#FORM.DetectSSDBuffer#&TestFileSizeOverride=#FORM.TestFileSizeOverride#&WaitBeforeRead=#FORM.WaitBeforeRead#&SeriesList1=#URLEncodedFormat(SeriesList1)#&SeriesList2=#URLEncodedFormat(SeriesList2)#">
	<CFLOOP index="ChkDrive" list="#Test[Key]#">
		<!--- Each controller is testing x number of SSD's. Each "SSDSpot" ia assigned to one drive. Add number of SSD's being parsed and increment this for the next controller.
			  This is used to "single-thread" the SSD benchmarks so only one is being tested at a time --->
		<CFIF HW[Key].Ports[Ref.DriveID[ChkDrive].PortNo].Attrib.Configuration.RPM EQ "Solid State Device">
			<CFSET SSDSpot=SSDSpot + 1>
		</CFIF>
	</CFLOOP>
	<table border="0" cellpadding="0" cellspacing="0">
		<tr>
			<td valign="middle">
				<div id="#ControllerID#">#HW[Key].Config.Product#: Starting...</div>
			</td>
			<td>&nbsp;&nbsp;</td>
			<td id="Progress_#ControllerID#_td">
				<table border="0" cellpadding="0" cellspacing="0">
					<tr>
						<td><progress id="Progress_#ControllerID#" value="0" max="100"></progress></td>
						<td>&nbsp;</td>
						<td><div id="Progress_#ControllerID#_Per">0%</div></td>
						<td>&nbsp;</td>
						<td><div id="Speed_#ControllerID#">&nbsp;</div></td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
	<iframe src="BenchmarkDriveController.cfm?#URLVal#" width="1400" height="400" style="display:none" id="#ControllerID#_debug"></iframe>
</CFLOOP>
<script language="Javascript">
var Debugging=0;
function ShowDebug()
{
	if (Debugging == 0) {
		Debugging=1;
		<CFLOOP index="Key" list="#DebugIDs#">
			document.getElementById('#Key#').style.display='block';
		</CFLOOP>
	} else {
		Debugging=0;
		<CFLOOP index="Key" list="#DebugIDs#">
			document.getElementById('#Key#').style.display='none';
		</CFLOOP>
	}
}
</script>
<!--- #TestDrives#<br>
#CheckDrives# --->
</CFOUTPUT>


<!--- <cfdump var=#test#>
<cfdump var=#driveslot#> --->
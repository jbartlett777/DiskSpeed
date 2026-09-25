<cfsetting enablecfoutputonly="true" requesttimeout="9999">

<CFPARAM name="FORM.SyncDrives" default="N">
<CFPARAM name="FORM.FineTune" default="N">
<CFPARAM name="FORM.Go" default="">
<CFPARAM name="FORM.Cancel" default="">
<CFPARAM name="FORM.Seconds" default="30">

<CFIF FORM.Cancel EQ "Cancel">
	<CFLOCATION URL="index.cfm" addtoken="NO">
</CFIF>

<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
<CFELSE>
	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>

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
				<CFSET Label=HW[Key].Ports[PortNo].UNRAIDSlot>
				<CFIF FindNoCase(CheckLabel,Label) GT 0 OR (CheckLabel EQ "" AND Label EQ "")>
					<CFIF Label NEQ "">
						<CFSET Label=LJustify(Label,20)>
					</CFIF>
					<CFSET CheckDrives[LabelSort]=ListAppend(CheckDrives[LabelSort],"#Label#|#DriveID#")>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFLOOP>
<CFSET CheckDrives=ListSort(CheckDrives.Parity,"text") & "," & ListSort(CheckDrives.Cache,"text") & "," & ListSort(CheckDrives.Disk,"text") & "," & ListSort(CheckDrives.Other,"text")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>
<CFSET CheckDrives=Replace(CheckDrives,",,",",","ALL")>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="#Highcharts#/highcharts.js"></script>
<script type="text/javascript" src="#Highcharts#/highcharts-more.js"></script>
<script type="text/javascript" src="/includes/highcharts_no-data-to-display.js"></script>
<script type="text/javascript" src="/includes/highcharts-regression.js"></script>
<style type="text/css">
body {font-family:Arial, Helvetica, sans-serif;}
td {font-family:Arial, Helvetica, sans-serif;}
.Bold {font-weight:bold;}
.Size14 {font-size:14px;}
.Size24 {font-size:24px;}
.Red {color:red;}
.Hand {cursor:pointer;}
.NOBR {white-space:nowrap;}
.Columns {-moz-column-width:135px;-webkit-column-width:135px;column-width:135px;}
.FloatLeft {float:left;}
.BR {clear:left;}
.Container {min-width:300px;max-width:400px;height:200px;margin:0 auto;}
</style>
</head>
<body>
<div onClick="location.href='index.cfm'" class="Hand">
</CFOUTPUT>
<CFINCLUDE template="DispHeader.cfm">
<CFOUTPUT>
</div>
</CFOUTPUT>

<CFIF FORM.GO NEQ "Start Drive Optimization">
	<CFOUTPUT>
	<div style="width:800px;">

	</div>
	<br>
	<table border="0" cellpadding="0" cellspacing="0">
		<tr>
			<td>
				<form method="POST" onSubmit="return Validations()">
				Test drives every
				<select name="Per" size="1">
				<CFLOOP index="Per" list="1,2,5,10,20,25">
					<CFIF Per EQ 10>
						<option value="#Per#" SELECTED>#Per#%</option>
					<CFELSE>
						<option value="#Per#">#Per#%</option>
					</CFIF>
				</CFLOOP>
				</select> of the hard drive<br>
				<input type="Checkbox" name="Drives" id="AllDrivesCheckbox" value="All" CHECKED onChange="ToggleAllDrives()"> <label for="AllDrivesCheckbox">Check all drives</label><br>
				<fieldset id="AllDriveList" style="display:none;">
					<legend>Select Drives to Optimize</legend>
					<div class="Columns NOBR">
					<CFSET ValJS="">
					<CFLOOP index="CurrDrive" list="#CheckDrives#">
						<CFSET tmpDriveID=Trim(ListLast(CurrDrive,"|"))>
						<CFSET tmpLabel=Trim(ListFirst(CurrDrive,"|"))>
						<CFSET ValJS=ValJS & "if (document.getElementById('Check_#tmpDriveID#').checked == true) DrivesSelected++;" & Chr(10)>
						<div class="FloatLeft"><input type="Checkbox" name="Drives" id="Check_#tmpDriveID#" value="#tmpDriveID#" onChange="ToggleDrive(this)"></div>
						<div class="FloatLeft">
							<label for="Check_#tmpDriveID#"><div class="FloatLeft" style="width:#Len(tmpDriveID)#0px;">#tmpDriveID#</div><CFIF tmpLabel NEQ tmpDriveID><div class="FloatLeft"> (#tmpLabel#)</div></CFIF></label>
						</div>
						<br>
					</CFLOOP>
					</div>
				</fieldset>
				<br>
				<input type="submit" name="go" value="Start Drive Optimization">
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
	</table>
	<script language="JavaScript">
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

<CFSET C=Chr(10)>
<CFSET script="">
<CFSET KeyIdx=0>
<CFSET TotalDrivesToTest=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF HW[Key].TotalDrives GT 0>
		<CFSET KeyIdx=KeyIdx + 1>
		<CFSET Active=0>
		<CFSET Done="">
		<CFSET script=script & "## Controller " & HW[Key].Config.Device & " [#Key#]" & C>
		<CFSET script=script & "Controller_#KeyIdx#_Curr=0" & C>
		<CFSET script=script & "Controller_#KeyIdx#_Max=" & HW[Key].MaxReadDrives & C>
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
			<CFIF DriveID NEQ "">
				<CFSET TotalDrivesToTest=TotalDrivesToTest + 1>
				<CFSET Dir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir & "/benchmark">
				<CFIF DirectoryExists(Dir) EQ "NO">
					<CFDIRECTORY action="create" directory="#Dir#" mode="666">
				</CFIF>
				<CFIF ListFind(FORM.Drives,"All") OR ListFind(FORM.Drives,DriveID)>
					<CFSET script=script & "## Drive #DriveID# - " & HW[Key].Ports[PortNo].Config.SaveDir & C>
					<CFSET TotalBlocks=HW[Key].Ports[PortNo].Attrib.Size.Bytes / HW[Key].Ports[PortNo].OptimalBlockSize>
					<CFSET script=script & "Dir=""#Dir#""" & C &
										   "PerCnt=0" & C>
					<CFLOOP index="i" from="0" to="100" step="#FORM.Per#">
						<CFSET script=script & "if [ -e ""$DIR/" & Replace(RJustify(i,3)," ","0","ALL") & ".bench.txt"" ];then" & C &
											   "	PerCent=$(( PerCent + #Form.Per# ))" & C &
											   "else" & C &
											   "fi" & C>
					</CFLOOP>
					<CFSET script=script & "PerCent=$(( PerCent - #Form.Per# ))" & C &
										   "if [[ PerCent -eq 100 ]]; then" & C &
										   "	let TotalDrivesTested++" & C &
										   "fi" & C>
				</CFIF>
			</CFIF>
			<CFSET script=script & C>
		</CFLOOP>
	</CFIF>
</CFLOOP>
<CFSET script="TotalDrivesTested=0" & C & "TotalDrivesToTest=#TotalDrivesToTest#" & C & script>


<cfoutput><pre>#script#</pre></cfoutput>

<cfdump var=#form#>

<CFPARAM name="FORM.ControllerDebug" default="">
<CFPARAM name="URL.Back" default="">
<CFPARAM name="FORM.Back" default="">

<CFFUNCTION name="DisplayDialog">
	<CFARGUMENT name="ControllerDebug" type="Number" required="false" default="0">

	<CFOUTPUT>
	<!DOCTYPE html>
	<html>
	<body>
	<style type="text/css">
	body {font-family:Arial, Helvetica, sans-serif;}
	td {font-family:Arial, Helvetica, sans-serif;}
	.Size5 {font-size:5px;}
	.Size12 {font-size:12px;}
	.Size14 {font-size:14px;}
	.Size18 {font-size:18px;}
	.Size24 {font-size:24px;}
	.Black {color:black;}
	</style>
	<br><br><br><br>
	<center>
	<script language="Javascript">
	function StartBigDebug() {
		//document.getElementById('buttons').style.display='none';
		//document.getElementById('generating').style.display='block';
		return true;
	}
	function o(txt) {
		document.getElementById('out').innerHTML=txt;
	}
	</script>
	<table border="0" cellpadding="0" cellspacing="0">
		<tr>
			<td valign="middle" class="Size18 Black">
				<center>
				<table border="0" cellpadding="0" cellspacing="0">
					<CFIF Arguments.ControllerDebug EQ 0>
						<tr id="buttons">
							<td valign="top">
								<form action="/isolated/CreateDebugInfo.cfm" method="POST" id="smalldebug">
								<input type="hidden" name="ControllerDebug" value="0">
								<input type="hidden" name="Back" value="#URL.Back#">
								<input type="submit" value="Create Debug File">
								</form>
							</td>
							<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
							<td valign="top">
								<form action="/isolated/CreateDebugInfo.cfm" onclick="return StartBigDebug()" method="POST" id="bigdebug">
								<input type="hidden" name="ControllerDebug" value="1">
								<input type="hidden" name="Back" value="#URL.Back#">
								<input type="submit" value="Create Debug File with Controller Info"><br>
								<span class="Size12">Click this if you have Unknown Controllers<br>or missing drives (debug file will be larger)</span>
								</form>
							</td>
							<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
							<td valign="top">
								<form action="/isolated/CreateDebugInfo.cfm" onclick="return StartBigDebug()" method="POST" id="hugedebug">
								<input type="hidden" name="ControllerDebug" value="2">
								<input type="hidden" name="Back" value="#URL.Back#">
								<input type="submit" value="Create Debug File with Full Hardware Info"><br>
								<span class="Size12">Only request this if asked by the Developer<br>(debug file will be huge and take awhile)<br>Please be patient</span>
								</form>
							</td>
						</tr>
					<CFELSE>
						<tr id="generating">
							<td valign="middle" align="center">
								<div id="wait" class="Size24">Please wait, creating debug file...</div>
								<br>
								<div id="out">Scanning Hardware...</div>
							</td>
						</tr>
					</CFIF>
				</table>
				</center>
			</td>
		</tr>
	</table>
	</center>
	<br><br><br><br>
	</body>
	</html>
	</CFOUTPUT>
</CFFUNCTION>

<CFIF FORM.ControllerDebug EQ "">
	<CFSET DisplayDialog()>
	<CFABORT>
</CFIF>

<CFSET DisplayDialog(1)>
<CFFLUSh>
<CFSET FetchURL=ListFirst(CGI.Request_URL,"/") & "//" & ListGetAt(CGI.Request_URL,2,"/") & "/ScanControllers.cfm?Debug=Export">
<CFHTTP method="GET" URL="#FetchURL#" throwOnError="no" redirect="no" path="#PersistDir#/debug/ScanControllers.html" timeout="120"></CFHTTP>
<CFTRY>
	<cfexecute name="/bin/chmod" arguments="666 #PersistDir#/debug/ScanControllers.html" timeout="10" />
<CFCATCH Type="Any">
</CFCATCH>
</CFTRY>

<CFSET InstanceDir="">
<CFLOOP index="i" FROM="1" to="#Len(Config.var.RegTo)#">
	<CFIF FindNoCase(Mid(Config.var.RegTo,i,1),"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")>
		<CFSET InstanceDir=InstanceDir & Mid(Config.var.RegTo,i,1)>
	</CFIF>
</CFLOOP>
<CFSET ExportDir="/tmp/DiskSpeed/export">
<CFIF DirectoryExists("#ExportDir#")>
	<CFDIRECTORY action="delete" directory="#ExportDir#" recurse="true">
</CFIF>
<CFDIRECTORY action="create" directory="#ExportDir#/DiskSpeed/Instances/#InstanceDir#" createpath="true" mode="666">
<CFDIRECTORY action="create" directory="#ExportDir#/DiskSpeed/Instances/#InstanceDir#/SMARTData" mode="666">
<CFDIRECTORY action="create" directory="#ExportDir#/DiskSpeedTmp/Instances/#InstanceDir#" mode="666">
<CFOUTPUT><script>o('Exporting DiskSpeed Data...');</script></CFOUTPUT><CFFLUSH>
<cfexecute name="/bin/cp" arguments="-r /tmp/DiskSpeed/Instances/local/. #ExportDir#/DiskSpeed/Instances/#InstanceDir#" timeout="60" />
<CFOUTPUT><script>o('Exporting DiskSpeed Runtime Data...');</script></CFOUTPUT><CFFLUSH>
<cfexecute name="/bin/cp" arguments="-r /tmp/DiskSpeedTmp/Instances/local/. #ExportDir#/DiskSpeedTmp/Instances/#InstanceDir#" timeout="60" />
<CFIF FileExists("/var/local/emhttp/disks.ini")>
	<CFFILE action="COPY" source="/var/local/emhttp/disks.ini" destination="#ExportDir#/DiskSpeed/Instances/#InstanceDir#/disks.ini" mode="666">
</CFIF>
<CFIF DirectoryExists("/var/local/emhttp/smart")>
	<CFOUTPUT><script>o('Exporting Drive SMART Data...');</script></CFOUTPUT><CFFLUSH>
	<CFDIRECTORY action="list" directory="/var/local/emhttp/smart" name="Dir">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="COPY" source="/var/local/emhttp/smart/#Dir.Name[CR]#" destination="#ExportDir#/DiskSpeed/Instances/#InstanceDir#/SMARTData/#Dir.Name[CR]#" mode="666">
	</CFLOOP>
</CFIF>
<CFDIRECTORY action="list" directory="#ExportDir#" filter="user.png" recurse="true" name="Files">
<CFLOOP index="i" from="1" to="#Files.RecordCount#">
	<CFFILE action="delete" file="#Files.Directory[i]#/#Files.Name[i]#">
</CFLOOP>

<CFIF Val(FORM.ControllerDebug) GTE 1>
	<CFDIRECTORY action="create" directory="#ExportDir#/DiskSpeed/Instances/#InstanceDir#/Devices" createpath="true" mode="666">
	<CFIF FORM.ControllerDebug EQ 1>
		<CFOUTPUT><script>o('Exporting PCI Bus Information...');</script></CFOUTPUT><CFFLUSH>
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/ExportTree.sh" output="/usr/bin/tree /sys/devices/pci* > #ExportDir#/DiskSpeed/Instances/#InstanceDir#/Devices/tree.txt" mode="766">
	<CFELSEIF FORM.ControllerDebug EQ 2>
		<CFOUTPUT><script>o('Exporting All Device Information... (this will take a bit)');</script></CFOUTPUT><CFFLUSH>
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/ExportTree.sh" output="/usr/bin/tree /sys/devices/* > #ExportDir#/DiskSpeed/Instances/#InstanceDir#/Devices/tree.txt" mode="766">
	</CFIF>
	<CFTRY>
		<cfexecute name="/tmp/DiskSpeedTmp/ExportTree.sh" timeout="60" />
	<CFCATCH Type="Any">
	</CFCATCH>
	</CFTRY>
	<CFIF FORM.ControllerDebug EQ 1>
		<CFDIRECTORY action="list" directory="/sys/devices" filter="pci*" type="dir" name="pci">
	<CFELSEIF FORM.ControllerDebug EQ 2>
		<CFDIRECTORY action="list" directory="/sys/devices" type="dir" name="pci">
	</CFIF>
	<CFSET Out="">
	<CFLOOP index="CR" from="0" to="#pci.RecordCount#">
		<CFIF CR EQ 0>
			<CFOUTPUT><script>o('Exporting Docker internal infomration at /sys/fs/cgroup');</script></CFOUTPUT><CFFLUSH>
			<CFSET Out="/usr/bin/find '/sys/fs/cgroup' -type f -size -100b -perm /u+r >> /tmp/DiskSpeedTmp/files.txt" & Chr(10)>
		<CFELSE>
			<CFOUTPUT><script>o('Exporting information files under /sys/devices/#EncodeForJavascript(pci.Name[CR])#');</script></CFOUTPUT><CFFLUSH>
			<CFSET Out="/usr/bin/find '/sys/devices/#pci.Name[CR]#/' -type f -size -100b -perm /u+r >> /tmp/DiskSpeedTmp/files.txt" & Chr(10)>
		</CFIF>
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/files.txt" output="" mode="666" addnewline="NO">
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/ExportFiles.sh" output="#Out#" mode="766" addnewline="NO">
		<cfexecute name="/tmp/DiskSpeedTmp/ExportFiles.sh" timeout="60" />
		<CFFILE action="read" file="/tmp/DiskSpeedTmp/files.txt" variable="files">
		<CFLOOP index="CurrLine" list="#files#" delimiters="#Chr(10)#">
			<CFIF FindNoCase("usb",CurrLine) EQ 0>
				<CFSET DestFile=ListLast(CurrLine,"/")>
				<CFSET DestDir=ListDeleteAt(CurrLine,ListLen(CurrLine,"/"),"/")>
				<CFSET DestDir=ListDeleteAt(DestDir,1,"/")>
				<CFSET DestDir=ListDeleteAt(DestDir,1,"/")>
				<CFSET DestDir=Replace(DestDir,":","_","ALL")>
				<CFSET DestDir="#ExportDir#/DiskSpeed/Instances/#InstanceDir#/Devices/" & DestDir>
				<CFIF DirectoryExists(DestDir) EQ "NO">
					<CFDIRECTORY action="create" directory="#DestDir#" createpath="true" mode="666">
				</CFIF>
				<CFTRY>
					<CFFILE action="copy" source="#CurrLine#" destination="#DestDir#/#DestFile#.txt" mode="666">
					<CFCATCH Type="Any">
						<!--- Eat any errors --->
					</CFCATCH>
				</CFTRY>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFIF>

<CFSET ExportFile=InstanceDir & "_" & DateFormat(Now(),"yyyymmdd") & "_" & TimeFormat(Now(),"HHmmss") & ".tar.gz">
<CFOUTPUT><script>o('Creating #EncodeForJavascript(ExportFile)#');</script></CFOUTPUT><CFFLUSH>
<cfexecute name="/bin/tar" arguments="-zcvf /tmp/DiskSpeed/#ExportFile# #ExportDir#" timeout="300" />
<cfexecute name="/bin/chmod" arguments="666 /tmp/DiskSpeed/#ExportFile#" timeout="10" />
<CFIF DirectoryExists("#ExportDir#")>
	<CFDIRECTORY action="delete" directory="#ExportDir#" recurse="true">
</CFIF>

<CFSAVECONTENT variable="HTML">
<CFOUTPUT>
The file <b>#ExportFile#</b> has been created in your DiskSpeed mounted volume.<br>
<br>
Please email it to <a href="mailto:harddrivedb@gmail.com?subject=Debug%20file%20#InstanceDir#">harddrivedb@gmail.com</a> and include as
much information as you can what issues you are experiencing.<br>
<br>
If the file is too large to email, upload it to a service such as Google Drive and include a link to the file in the email instead.
<CFIF FORM.Back NEQ "">
	<br>
	<br>
	<a href="/">Continue</a>
</CFIF>
</CFOUTPUT>
</CFSAVECONTENT>

<CFOUTPUT>
<script>o('#EncodeForJavascript(HTML)#');
document.getElementById('wait').style.display='none';
</script>
</body>
</html>
</CFOUTPUT>
<CFFLUSH>
<!---
<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<style type="text/css">
body {font-family:Arial, Helvetica, sans-serif;}
td {font-family:Arial, Helvetica, sans-serif;}
.Size5 {font-size:5px;}
.Size12 {font-size:12px;}
.Size14 {font-size:14px;}
.Size18 {font-size:18px;}
.Size24 {font-size:24px;}
.Black {color:black;}
</style>
<br><br><br><br>
<center>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td valign="middle" class="Size18 Black">
			The file #ExportFile# has been created in your &lt;appdata&gt;/DiskSpeed share.<br>
			<br>
			Please email it to <a href="mailto:harddrivedb@gmail.com?subject=Debug%20file%20#InstanceDir#">harddrivedb@gmail.com</a> and include as
			much information as you can what issues you are experiencing.<br>
			<br>
			If the file is too large to email, upload it to a service such as Google Drive and include a link to the file in the email instead.
			<CFIF FORM.Back NEQ "">
				<br>
				<br>
				<a href="/">Continue</a>
			</CFIF>
		</td>
	</tr>
</table>
</center>
<br><br><br><br>
</body>
</html>
</CFOUTPUT>
--->
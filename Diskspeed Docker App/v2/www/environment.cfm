<CFSET AppVer="2.10.10.4">

<CFPARAM name="URL.DontBackupJSON" default="N">
<CFPARAM name="Config.var.RegTo" default="">
<CFIF Config.var.RegTo EQ "">
	<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="10">
		<CFPARAM name="Application.IP" default="">
		<CFIF Application.IP EQ "">
			<CFHTTP URL="https://api.ipify.org"></CFHTTP>
			<CFIF CFHTTP.Status_Code EQ 200>
				<CFSET Application.IP=CFHTTP.FileContent>
			<CFELSE>
				<CFSET Application.IP="Unknown">
			</CFIF>
		</CFIF>
		<CFSET Config.var.RegTo=Application.IP>
		<CFSET Config.Var.RegGUID="Unknown">
	</cflock>
</CFIF>
<CFSET UserID=Config.var.RegTo & "_" & Config.var.RegGUID>
<CFSET UserID=REReplaceNoCase(UserID,"[^A-Z0-9]","_","ALL")>

<CFSET CurrInstance="">
<CFPARAM name="Application.CurrInstance" default="local">
<CFIF CurrInstance NEQ "">
	<CFSET Application.CurrInstance=CurrInstance>
</CFIF>
<CFSET CurrInstance=Application.CurrInstance>

<CFSET RootDir=ExpandPath(".")>
<CFIF ListLast(RootDir,"/") EQ "isolated">
	<CFSET RootDir=ListDeleteAt(RootDir,ListLen(RootDir,"/"),"/")>
</CFIF>
<CFSET SaveDir="/tmp/DiskSpeedTmp/Instances/" & CurrInstance>
<CFSET PersistDir="/tmp/DiskSpeed/Instances/" & CurrInstance>

<CFSET Highcharts="/includes/Highcharts-10.3.3/code">
<CFSET Highmaps="/includes/Highcharts-Maps-10.3.3/code">
<CFSET Highstocks="/includes/Highcharts-Stock-10.3.3/code">
<CFSET HighchartsBoost="#Highcharts#/modules/boost.js">

<CFSET DebugFlag=0>
<CFIF FileExists("/tmp/DiskSpeed/debug.txt")>
	<CFSET DebugFlag=1>
</CFIF>

<!---<CFSET OneGB=1073741824>--->
<CFSET OneGB=1000000000>
<!---<CFSET SSDBenchmarkTestFiles_Max=50>--->
<CFSET SSDBenchmarkTestFiles_Default=15>
<CFSET MinSSDSpaceFreeDefault=5> <!--- 5 gb --->
<!---<CFSET NumJobs=4>--->
<CFSET NRFiles=4>
<CFSET CacheExhaustedPercentage=70>
<CFSET SustainedWritePercentage=10> <!--- % above & below 100% for the allowed range in determining if the current Read MB/s is close to the previous Read MB/Sec --->
<CFSET BenchmarkSSDBounceMinFileCnt=10>
<CFSET BenchmarkSSDBounceMinPercentage=33>

<CFSET DriveWidth=128>
<CFSET DriveHeight=175>
<CFSET BlockSizeList="512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432">
<CFSET BlockSizeListDisp="512B,1K,2K,4K,8K,16K,32K,64K,128K,256K,512K,1M,2M,4M,8M,16M,32M">
<CFSET C=Chr(10)>
<CFSET SpinupBlockCount=5>
<CFSET HeatmapGroupCap=25000000>
<CFSET WebRoot=ListFirst(CGI.Request_URL,"/") & "//" & CGI.Server_Name & ":" & CGI.Server_Port>

<CFIF DirectoryExists("#SaveDir#/optimize") EQ "NO">
	<CFDIRECTORY action="create" directory="#SaveDir#/optimize" createpath="true" mode="666">
</CFIF>
<CFIF DirectoryExists("#SaveDir#/pids") EQ "NO">
	<CFDIRECTORY action="create" directory="#SaveDir#/pids" createpath="true" mode="666">
</CFIF>
<CFIF DirectoryExists("#PersistDir#/controller") EQ "NO">
	<CFDIRECTORY action="create" directory="#PersistDir#/controller" createpath="true" mode="666">
</CFIF>
<CFIF DirectoryExists("#PersistDir#/driveinfo") EQ "NO">
	<CFDIRECTORY action="create" directory="#PersistDir#/driveinfo" mode="666">
</CFIF>
<CFIF DirectoryExists("#PersistDir#/debug") EQ "NO">
	<CFDIRECTORY action="create" directory="#PersistDir#/debug" mode="666">
</CFIF>

<!--- If developer flag is set, check to see if we are overriding the remote URL --->
<CFSET DiskSpeedDeveloper=0>
<CFIF FileExists("/tmp/DiskSpeed/DiskSpeedDeveloper.txt")>
	<CFSET DiskSpeedDeveloper=1>
</CFIF>

<CFIF FileExists("/tmp/DiskSpeed/HostOverride.txt")>
	<CFSET StrangeJourney=FileRead("/tmp/DiskSpeed/HostOverride.txt")>
<CFELSE>
	<CFSET StrangeJourney="https://strangejourney.net">
</CFIF>
<CFIF Trim(StrangeJourney) EQ "">
	<CFSET StrangeJourney="https://strangejourney.net">
</CFIF>

<CFSET Version=0>
<CFIF FileExists("#RootDir#/version.txt")>
	<CFFILE action="read" file="#RootDir#/version.txt" variable="Version">
</CFIF>

<CFIF FileExists("#RootDir#/version.txt") EQ "NO" OR DiskSpeedDeveloper EQ 1>
	<!--- Get Date of last modified CFM file for version --->
	<CFDIRECTORY action="list" directory="#RootDir#" name="Dir" filter="*.cfm" sort="datelastmodified desc" type="file" recurse="false">
	<CFSET NewVersion=DateFormat(Dir.DateLastModified[1],"yyyymmdd")>
	<CFIF NewVersion NEQ Version>
		<CFSET Version=NewVersion>
		<CFFILE action="write" file="#RootDir#/version.txt" output="#Version#" addnewline="NO" mode="666">
	</CFIF>
</CFIF>
<CFIF URL.DontBackupJSON EQ "N">
	<cflock name="BackupJSON" timeout="30" throwontimeout="yes" type="exclusive">
		<CFIF FileExists("#PersistDir#/storage.json")>
			<CFIF FileExists("#PersistDir#/storageold.json")>
				<CFIF FileInfo("#PersistDir#/storage.json").DateLastModified NEQ FileInfo("#PersistDir#/storageold.json").DateLastModified>
					<CFFILE action="copy" source="#PersistDir#/storage.json" destination="#PersistDir#/storageold.json" mode="666">
				</CFIF>
			<CFELSE>
				<CFFILE action="copy" source="#PersistDir#/storage.json" destination="#PersistDir#/storageold.json" mode="666">
			</CFIF>
		</CFIF>
	</cflock>
</CFIF>

<CFIF FileExists("/tmp/DiskSpeedTmp/ls.sh") EQ "NO">
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/ls.sh" output="if [ -d ""$1"" ]; then#Chr(10)#ls -l $1#Chr(10)#fi#Chr(10)#" addnewline="NO" mode="766">
	</cflock>
</CFIF>

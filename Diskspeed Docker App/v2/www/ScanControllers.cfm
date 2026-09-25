<cfsetting enablecfoutputonly="true" showdebugoutput="false" requesttimeout="300">
<CFINCLUDE TEMPLATE="CustomTags.cfm" runonce="true">
<CFINCLUDE TEMPLATE="environment.cfm" runonce="true">

<CFSET ScanTimedout=1>
<cflock name="ScanControllers" type="exclusive" throwontimeout="false" timeout="5">
<CFSET ScanTimedout=0>

<CFPARAM name="URL.SysChange" default="">
<CFPARAM name="URL.Debug" default="FOOBAR">
<CFPARAM name="URL.BadConfig" default="0">
<CFPARAM name="URL.OptInPreview" default="">

<!--- Import Seefusion if available
<CFIF FileExists("/tmp/DiskSpeed/seefusion5-2.jar") AND FileExists("/tmp/DiskSpeed/server.xml") AND FileExists("/usr/local/tomcat/lib/seefusion5-2.jar") EQ "NO">
	<CFFILE action="copy" source="/tmp/DiskSpeed/seefusion5-2.jar" destination="/usr/local/tomcat/lib/seefusion5-2.jar" mode="666">
	<CFFILE action="copy" source="/tmp/DiskSpeed/server.xml" destination="/usr/local/tomcat/conf/server.xml" mode="666">
	<CFOUTPUT>SeeFusion has been installed. Please restart Lucee.</CFOUTPUT>
	<CFABORT>
</CFIF> --->

<!--- Check to see if something is buffering the output --->
<CFOUTPUT>
<script>
var startTime = performance.now();
</script>
</CFOUTPUT>

<cfscript>
ErrorFlag=0;
ErrorReason="";
EXECCnt=0;
function EXE() {
	EXECCnt=EXECCnt + 1;
	return "debug/" & Replace(RJustify(EXECCnt,4)," ","0","ALL");
}
</cfscript>

<CFINCLUDE TEMPLATE="SMARTOptIn.cfm">

<cfscript>
// Default values
Drive=StructNew();
Drive.DevicePath="";
Drive.DriveID="";
Drive.PortNo="";
Drive.PortNoNotFound=0;
Drive.ControllerPCID="";
Drive.UNRAIDSlot="";
Drive.HDDBFound=0;
Drive.OptimalBlockSize=0;
Drive.OptimalBlockSizeSpeed=0;
Drive.DriveHash="";
Drive.ModelHash="";
Drive.UNRAIDSlotSrc="";
Drive.CDROM=0;
Drive.Attrib=StructNew();
Drive.Attrib.Vendor="";
Drive.Attrib.Model="";
Drive.Attrib.Rev="";
Drive.Attrib.Serial="";
Drive.Attrib.Product="";
Drive.Attrib.Capabilities="";
Drive.Attrib.Description="";
Drive.Attrib.Sizegib=0;
Drive.Attrib.Version="";
Drive.Attrib.USB=0;
Drive.Attrib.USBSpeed="";
Drive.Attrib.Removeable=0;
Drive.Attrib.ReadOnly=0;
Drive.Attrib.ReadAheadKB=0;
Drive.Attrib.PlatterCnt=0;
Drive.Attrib.HeadCnt=0;
Drive.Attrib.ShortStroked=0;
Drive.Attrib.MDTS=0;
Drive.Attrib.LBADS=0;
Drive.Attrib.Size=StructNew();
Drive.Attrib.Size.DispSize="";
Drive.Attrib.Size.Size="";
Drive.Attrib.Size.Bytes=0;
Drive.Attrib.Size.BlockCount=0;
Drive.Attrib.Configuration=StructNew();
Drive.Attrib.Configuration.MultipleSectorTransfer=StructNew();
Drive.Attrib.Configuration.MultipleSectorTransfer.Current=0;
Drive.Attrib.Configuration.MultipleSectorTransfer.Max=0;
Drive.Attrib.Configuration.LogicalSectorSize=0;
Drive.Attrib.Configuration.SectorSize=0;
Drive.Attrib.Configuration.SignalingSpeed=0;
Drive.Attrib.Configuration.SignalingSpeedDisp="";
Drive.Attrib.Configuration.SectorZeroOffset=0;
Drive.Attrib.Configuration.RPM=0;
Drive.Attrib.Configuration.MaxSectorsPerRequest=0;
Drive.Attrib.Configuration.BlockCount=0;
Drive.Attrib.Configuration.NVMeVer=0;
Drive.IDs=StructNew();
Drive.IDs.NGID="";
Drive.IDs.NSID="";
Drive.IDs.UUID="";
Drive.IDs.WWID="";

BlankUSBConfig.TextOverlay=1;
BlankUSBConfig.TextRotation=0;
BlankUSBConfig.DefaultImage=0;
BlankUSBConfig.TextFont="Arial";
BlankUSBConfig.TextBold=0;
BlankUSBConfig.DriveEdited=0;
BlankUSBConfig.TextItalics=0;
BlankUSBConfig.FetchInfo=0;
BlankUSBConfig.CenterX=1;
BlankUSBConfig.CenterY=1;
BlankUSBConfig.ImageHeight=190;
BlankUSBConfig.FontColor="000000";
BlankUSBConfig.FontSize=18;
BlankUSBConfig.ImageWidth=128;

BlankController=StructNew();
BlankController.SVendor="";
BlankController.ControllerOptimized=0;
BlankController.MaxReadDrives=1;
BlankController.Type="storage";
BlankController.TotalDrives=0;
BlankController.TotalPorts=0;
BlankController.USB=0;
BlankController.USBSpeed=0;
BlankController.NVMe=0;
BlankController.Path="";
BlankController.BandwidthHash="";
BlankController.Parents=ArrayNew(1);
BlankController.Ports=ArrayNew(1);
BlankController.Config=StructNew();
BlankController.Config.LnkSta.Speed="";
BlankController.Config.LnkCap.Speed="";
BlankController.Config.Width="";
BlankController.Config.Clock="";
BlankController.Config.Device="Unknown Controller";
BlankController.Config.PCISlot="Unknown";
BlankController.Config.Vendor="";
BlankController.Config.Class="";
BlankController.Config.Product="Unknown Controller";
BlankController.Config.LnkCap=StructNew();
BlankController.Config.LnkCap.Speed="";
BlankController.Config.LnkCap.Width="";
BlankController.Config.LnkCap.PCIeVer="";
BlankController.Config.LnkCap.Throughput="";
BlankController.Config.LnkCap.ThroughputMB="";
BlankController.Config.LnkSta=StructNew();
BlankController.Config.LnkSta.Width="";
BlankController.Config.LnkSta.PCIeVer="";
BlankController.Config.LnkSta.ThroughputMB="";
BlankController.Config.Capabilities="";
BlankController.Config.Resources="";
BlankControllerConfig=Duplicate(BlankController.Config);
</cfscript>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<title>DiskSpeed</title>
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
.DivTable {display:table;}
.DivRow {display:table-row;}
.DivCell {display:table-cell;}
.KindaHidden { opacity: 0.01 !important;}
</style>
</head>
<body>
<div onClick="location.href='index.cfm'" class="Hand">
</CFOUTPUT>
<CFINCLUDE template="DispHeader.cfm">
<CFOUTPUT>
</div>
</CFOUTPUT>

<CFSET OldHW="">
<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET OldHW=DeserializeJSON(json)>
</CFIF>
<CFIF FileExists("#PersistDir#/vendor_override.json")>
	<CFFILE action="read" file="#PersistDir#/vendor_override.json" variable="json">
	<CFSET VendorOverride=DeserializeJSON(json)>
<CFELSE>
	<CFSET VendorOverride=StructNew()>
</CFIF>

<!--- Check to see if the Docker can see PCI devices --->
<cfexecute name="/usr/bin/lspci" timeout="300" variable="lspci" />
<CFIF Len(StripCRLF(lspci)) EQ 0>
	<CFOUTPUT>
	<br><br>
	DiskSpeed is either not running in Privleged Mode or is running on Windows and can not proceed.<br>
	</CFOUTPUT>
	<CFABORT>
</CFIF>

<!--- Delete any existing merged benchmarks --->
<CFIF FileExists("#PersistDir#/driveinfo/DriveBenchmarks.txt")>
	<CFFILE action="delete" file="#PersistDir#/driveinfo/DriveBenchmarks.txt">
</CFIF>

<!--- Reference table for controller link speed max throughput --->
<CFSET ColList="PCIeVer,TransferRate,x1,x2,x4,x8,x16,x32,LineCodeL,LineCodeH">
<CFSET LinkSpeed=QueryNew(ColList,"varchar,numeric,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer")>
<CFSET tmp=ArrayNew(1)>
<CFSET tmp[1]="1.0,2.5,250 MB/s,500 MB/s,1 GB/s,2 GB/s,4 GB/s,8 GB/s,8,10">
<CFSET tmp[2]="2.0,5,500 MB/s,1 GB/s,2 GB/s,4 GB/s,8 GB/s,16 GB/s,8,10">
<CFSET tmp[3]="3.0,8,984.6 MB/s,1.97 GB/s,3.94 GB/s,7.88 GB/s,15.8 GB/s,31.5 GB/s,128,130">
<CFSET tmp[4]="4.0,16,1.969 GB/s,3.94 GB/s,7.88 GB/s,15.75 GB/s,31.5 GB/s, 63 GB/s,128,130">
<CFSET tmp[5]="5.0,32,3.938 GB/s,7.88 GB/s,15.75 GB/s,31.51 GB/s,63 GB/s,126 GB/s,128,130">
<CFLOOP index="i" from="1" to="#ArrayLen(tmp)#">
	<CFSET QueryAddRow(LinkSpeed)>
	<CFLOOP index="c" from="1" to="#ListLen(ColList)#">
		<CFSET Cell=ListGetAt(ColList,c)>
		<CFSET QuerySetCell(LinkSpeed,Cell,ListGetAt(tmp[i],c))>
	</CFLOOP>
</CFLOOP>

<CFSET PCILinkSpeed=QueryNew("Type,Width,Clock,Speed","varchar,varchar,varchar,decimal")>
<CFSET tmp=ArrayNew(1)>
<CFSET tmp[1]="PCI,32bit,33MHz,133.33">
<CFSET tmp[2]="PCI,64bit,33MHz,266.7">
<CFSET tmp[3]="PCI,32bit,66MHz,266.7">
<CFSET tmp[4]="PCI,64bit,66MHz,533.3">
<CFSET tmp[5]="PCI,64bit,100MHz,800">
<CFSET tmp[6]="IDE,32bit,33MHz,133.33">
<CFSET tmp[7]="IDE,64bit,33MHz,266.7">
<CFSET tmp[8]="IDE,32bit,66MHz,266.7">
<CFSET tmp[9]="IDE,64bit,66MHz,533.3">
<CFSET tmp[10]="IDE,64bit,100MHz,800">
<CFSET tmp[11]="PCI-X,64bit,66MHz,533.3">
<CFSET tmp[12]="PCI-X,64bit,100MHz,800">
<CFSET tmp[13]="PCI-X,64bit,133MHz,1067">
<CFLOOP index="i" from="1" to="#ArrayLen(tmp)#">
	<CFSET QueryAddRow(PCILinkSpeed)>
	<CFLOOP index="c" from="1" to="4">
		<CFSET Cell=ListGetAt("Type,Width,Clock,Speed",c)>
		<CFSET QuerySetCell(PCILinkSpeed,Cell,ListGetAt(tmp[i],c))>
	</CFLOOP>
</CFLOOP>

<CFIF DirectoryExists("#RootDir#/images/inuse") EQ "NO">
	<CFDIRECTORY action="create" directory="#RootDir#/images/inuse" mode="666">
</CFIF>
<CFIF DirectoryExists("#RootDir#/images/inuse/#CurrInstance#") EQ "NO">
	<CFDIRECTORY action="create" directory="#RootDir#/images/inuse/#CurrInstance#" mode="666">
</CFIF>

<!---
/usr/bin/lspci
/usr/bin/lsscsi
/usr/bin/lsusb
/usr/bin/lshw
/usr/bin/find
--->

<!--- Cleanup last log files --->
<CFDIRECTORY action="list" directory="#PersistDir#/debug" type="file" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="delete" file="#PersistDir#/debug/#Dir.Name[CR]#">
</CFLOOP>

<!--- Get block devices --->
<CFFILE action="write" file="#PersistDir#/#exe()#_ls_sysblock_exec.txt" output="/bin/ls -l /sys/block" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/bin/ls" arguments="-l /sys/dev/block" variable="tmp" timeout="90" />
<CFFILE action="write" file="#PersistDir#/#exe()#_ls_-l_sys_block.txt" mode="666" output="#tmp#" addnewline="NO">
<CFSET BlockDevices="">
<CFLOOP index="CurrLine" from="1" to="#ListLen(tmp,Chr(10))#">
	<CFIF Find("/usb",CurrLine) EQ 0 AND Find("/virtual",CurrLine) EQ 0>
		<CFSET BlockDevices=BlockDevices & CurrLine>
	</CFIF>
</CFLOOP>

<!--- Track hash of drives & partitions for changes --->
<CFFILE action="write" file="#PersistDir#/BlockHash.txt" output="#Hash36(Utils.GetBlockDevices())#" addnewline="NO" mode="666">

<CFFILE action="write" file="#PersistDir#/#exe()#_ls_sysblock_exec.txt" output="/bin/ls -l /sys/block" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/bin/ls" arguments="-l /sys/block" variable="BlockDevices" timeout="90" />
<CFFILE action="write" file="#PersistDir#/#exe()#_ls_sysblock.txt" output="#BlockDevices#" addnewline="NO" mode="666">

<cflock type="Exclusive" scope="Session" throwontimeout="true" timeout="30">
	<CFPARAM name="Session.ScanCount" default="0">
	<CFSET Session.ScanCount=Session.ScanCount + 1>
	<CFSET ScanCount=Session.ScanCount>
</cflock>
<CFOUTPUT>
<span class="Bold">Scanning Hardware
<CFIF URL.SysChange EQ "Y">
	- A change was detected on the drive configuration.
	<CFIF ScanCount GTE 3>
		<span class="Red">A loop has been detected. Please restart the DiskSpeed docker application if this continues.</span>
	</CFIF>
</CFIF>
<CFIF URL.BadConfig EQ "Y">
	- The saved configuration file was invalid, rescanning hardware to recreate it
	<CFIF ScanCount GTE 3>
		<span class="Red">A loop has been detected. Please restart the DiskSpeed docker application if this continues.</span>
	</CFIF>
</CFIF>


</span><br>
#TS()# Spinning up hard drives<br>
</CFOUTPUT>
<CFFLUSH>
<CFINCLUDE template="Spinup.cfm">

<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFSET HWCreate="">
	<CFIF StructKeyExists(HW,"Create")>
		<CFSET HWCreate=Duplicate(HW.Create)>
	</CFIF>
</CFIF>


<CFSET HW=StructNew()>
<CFSET MiscRef=StructNew()>

<CFOUTPUT>#TS()# Scanning system storage<br></CFOUTPUT><CFFLUSH>
<CFFILE action="write" file="#PersistDir#/#exe()#_hwinfo_storage_exec.txt" output="/usr/sbin/hwinfo --pci --bridge --storage-ctrl --disk --ide --scsi" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<CFTRY>
	<cfexecute name="/usr/sbin/hwinfo" arguments="--pci --bridge --storage-ctrl --disk --ide --scsi" variable="storage"  timeout="90" /><!---  --usb-ctrl --usb --hub --->
<CFCATCH Type="Any">
	<CFOUTPUT>
	<br>
	There was an error running the hwinfo utility. This may be caused due to drives having not been spun up on system with many drives as this utility will
	spin them up one at a time. Please verify your drives are spun up and then refresh your browser.
	</CFOUTPUT>
	<CFABORT>
</CFCATCH>
</CFTRY>
<CFFILE action="write" file="#PersistDir#/#exe()#_hwinfo_storage.txt" output="#storage#" addnewline="NO" mode="666">
<!--- Find max ID --->
<CFLOOP index="CurrLine" list="#storage#" delimiters="#Chr(10)#">
	<CFIF Left(CurrLine,1) NEQ " ">
		<CFSET MaxID=Val(CurrLine)>
	</CFIF>
</CFLOOP>
<CFSET HWTree=ArrayNew(1)>
<CFSET tmp=StructNew()>
<CFSET tmp["Hardware Class"]="unknown">
<CFSET tmp.ChildDrives=0>
<CFSET tmp["Parent ID"]="">
<CFSET tmp.Children=ArrayNew(1)>
<CFSET ArraySet(HWTree,1,MaxID,tmp)>
<CFLOOP index="CurrLine" list="#storage#" delimiters="#Chr(10)#">
	<CFIF Left(CurrLine,1) NEQ " ">
		<CFSET CurrID=Val(CurrLine)>
		<!--- <CFSET HWTree[CurrID].Desc=ListDeleteAt(CurrLine,1,":")> --->
		<CFSET HWTree[CurrID].Desc=CurrLine>
	<CFELSE>
		<CFIF ListLen(CurrLine,":") GT 1>
			<CFSET CurrVar=ListFirst(Trim(CurrLine),":")>
			<CFSET CurrVal=Trim(ListDeleteAt(CurrLine,1,":"))>
			<CFIF ListFindNoCase("pci,usb",ListFirst(CurrVal," ")) AND Right(CurrVal,1) EQ Chr(34)>
				<CFIF ListLen(ListGetAt(CurrVal,2," "),"x") EQ 2>
					<CFSET CurrVal=ListDeleteAt(CurrVal,1," ")>
					<CFSET CurrVal=ListDeleteAt(CurrVal,1," ")>
				</CFIF>
			</CFIF>
			<CFIF ListFindNoCase("Driver,Driver Modules",CurrVar)>
				<CFSET CurrVal=Replace(CurrVal,Chr(34),"","ALL")>
			<CFELSE>
				<CFIF Left(CurrVal,1) EQ Chr(34) AND Right(CurrVal,1) EQ Chr(34)>
					<CFSET CurrVal=Mid(CurrVal,2,Len(CurrVal)-2)>
				</CFIF>
			</CFIF>
			<CFSET HWTree[CurrID][CurrVar]=CurrVal>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFSET DeviceIDsToRemove="">
<!--- Get rid of items we don't need hardware classes --->
<CFLOOP index="CurrID" from="#ArrayLen(HWTree)#" to="1" step="-1">
	<CFIF ListFindNoCase("unknown,network,sound,graphics card,mouse,keyboard,floppy",HWTree[CurrID]["Hardware Class"])>
		<CFIF StructKeyExists(HWTree[CurrID],"Device File")>
			<CFSET DeviceIDsToRemove=ListAppend(DeviceIDsToRemove,ListLast(ListFirst(HWTree[CurrID]["Device File"]," "),"/"))>
		</CFIF>
		<CFSET ArrayDeleteAt(HWTree,CurrID)>
	</CFIF>
</CFLOOP>

<!--- Get the LSPCI description for each device --->
<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_-D_exec.txt" output="/usr/bin/lspci -D" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/usr/bin/lspci" arguments="-D" timeout="300" variable="lspci" />
<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_-D.txt" output="#lspci#" addnewline="no" mode="666">
<CFLOOP index="i" from="1" to="#ArrayLen(HWTree)#">
	<CFIF StructKeyExists(HWTree[i],"SysFS ID")>
		<CFSET Loc=ListContains(lspci,ListLast(HWTree[i]["SysFS ID"],"/"),Chr(10))>
		<CFIF Loc GT 0>
			<CFSET HWTree[i].Device=ListDeleteAt(ListGetAt(lspci,Loc,Chr(10)),1," ")>
		</CFIF>
	</CFIF>
</CFLOOP>
<!--- Nest items --->
<CFSET OK=0>
<CFLOOP condition="NOT OK">
	<!--- Find an item with no children --->
	<CFLOOP index="x" from="1" to="#ArrayLen(HWTree)#">
		<CFSET ParentFound=0>
		<CFLOOP index="y" from="1" to="#ArrayLen(HWTree)#">
			<CFIF HWTree[y]["Parent ID"] EQ HWTree[x]["Unique ID"]>
				<CFSET ParentFound=1>
				<CFBREAK>
			</CFIF>
		</CFLOOP>
		<CFSET ChildMoved=0>
		<CFIF NOT ParentFound>
			<!--- If we found an item with no children, find it's parent. If found, move it as a child --->
			<CFLOOP index="y" from="1" to="#ArrayLen(HWTree)#">
				<CFIF HWTree[x]["Parent ID"] EQ HWTree[y]["Unique ID"]>
					<CFSET HWTree[y].Children[ArrayLen(HWTree[y].Children)+1]=Duplicate(HWTree[x])>
					<CFIF HWTree[x]["Hardware Class"] EQ "disk">
						<CFSET HWTree[y].ChildDrives=HWTree[y].ChildDrives + HWTree[x].ChildDrives + 1>
					</CFIF>
					<CFSET ArrayDeleteAt(HWTree,x)>
					<CFSET ChildMoved=1>
					<CFBREAK>
				</CFIF>
			</CFLOOP>
		</CFIF>
		<CFIF ChildMoved EQ 1>
			<CFBREAK>
		</CFIF>
	</CFLOOP>
	<CFIF ChildMoved EQ 0>
		<CFSET OK=1>
	</CFIF>
</CFLOOP>
<!--- Set top level ChildDrives --->
<CFLOOP index="i" from="1" to="#ArrayLen(HWTree)#">
	<CFIF HWTree[i].ChildDrives EQ 0>
		<CFSET x=0>
		<CFLOOP index="q" from="1" to="#ArrayLen(HWTree[i].Children)#">
			<CFSET x=x+HWTree[i].Children[q].ChildDrives>
		</CFLOOP>
		<CFSET HWTree[i].ChildDrives=x>
	</CFIF>
</CFLOOP>
<!--- Remove empty drives --->
<CFLOOP index="i" from="1" to="#ArrayLen(HWTree)#">
	<CFIF StructKeyExists(HWTree[i],"Children")>
		<CFLOOP index="ChildID" from="1" to="#ArrayLen(HWTree[i].Children)#">
			<CFIF StructKeyExists(HWTree[i].Children[ChildID],"Drive Status")>
				<CFIF HWTree[i].Children[ChildID]["Drive Status"] EQ "no medium">
					<CFIF StructKeyExists(HWTree[i],"Device File")>
						<CFSET DeviceIDsToRemove=ListAppend(DeviceIDsToRemove,ListLast(ListFirst(HWTree[i]["Device File"]," "),"/"))>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<!--- Remove unused trees --->
<CFLOOP index="CurrID" from="#ArrayLen(HWTree)#" to="1" step="-1">
	<CFIF HWTree[CurrID].ChildDrives EQ 0>
		<CFSET ArrayDeleteAt(HWTree,CurrID)>
	</CFIF>
</CFLOOP>
<!--- Remove USB items --->
<CFLOOP index="CurrID" from="#ArrayLen(HWTree)#" to="1" step="-1">
	<CFIF FindNoCase("usb",HWTree[CurrID]["Hardware Class"])>
		<CFSET ArrayDeleteAt(HWTree,CurrID)>
	</CFIF>
</CFLOOP>

<CFOUTPUT>#TS()# Scanning USB Bus<br></CFOUTPUT><CFFLUSH>
<CFSET USBTree=ArrayNew(1)>
<CFFILE action="write" file="#PersistDir#/#exe()#_find_sys_devices_-name_usb_exec.txt" output="/usr/bin/find /sys/devices -name usb?" addnewline="no" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<CFEXECUTE name="/usr/bin/find" arguments="/sys/devices -name usb?" variable="USBList" timeout="30" />
<CFFILE action="write" file="#PersistDir#/#exe()#_find_sys_devices_-name_usb.txt" output="#USBList#" addnewline="no" mode="666">
<CFSET i=0>
<CFLOOP index="CurrLine" list="#USBList#" delimiters="#Chr(10)#">
	<CFSET i=i+1>
	<CFSET USBTree[i]=ParseUSB(CurrLine)>
	<CFSET Tmp=REMatchNoCase("[\da-f]{4}:[\da-f]{2}:[\da-f]{2}.[\da-f]{1}",CurrLine)>
	<CFIF ArrayLen(Tmp) NEQ 0>
		<CFSET USBTree[i].Bus=Tmp[ArrayLen(Tmp)]>
	</CFIF>
</CFLOOP>


<CFOUTPUT>#TS()# Scanning hard drives<br></CFOUTPUT><CFFLUSH>

<!--- Identify all attached drives and get the information on them --->
<CFFILE action="write" file="#PersistDir#/#exe()#_ls_sysblock_exec.txt" output="/bin/ls -l /sys/block" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/bin/ls" arguments="-l /sys/block" variable="BlockDevices"  timeout="90" />
<CFFILE action="write" file="#PersistDir#/#exe()#_ls_sysblock.txt" output="#BlockDevices#" addnewline="NO" mode="666">
<CFLOOP index="i" from="2" to="#ListLen(BlockDevices,Chr(10))#">
	<CFSET CurrLine=ListGetAt(BlockDevices,i,Chr(10))>
	<CFIF FindNoCase("virtual",CurrLine) EQ 0 AND FindNoCase("platform",CurrLine) EQ 0>
		<CFSET DrivePath="/sys/" & ListDeleteAt(ListLast(CurrLine,">"),1,"/")>
		<CFSET CurrDrive=Duplicate(Drive)>
		<CFSET CurrDrive.DevicePath=DrivePath>
		<CFSET CurrDrive.DriveID=ListLast(DrivePath,"/")>
		<CFSET CurrDrive.Attrib.ReadOnly=StripCRLF(ReadFile("#DrivePath#/ro","0"))>
		<CFSET CurrDrive.Attrib.Removeable=StripCRLF(ReadFile("#DrivePath#/removable","0"))>
		<CFSET CurrDrive.Attrib.ReadAheadKB=StripCRLF(ReadFile("#DrivePath#/bdi/read_ahead_kb","0"))>
		<CFSET CurrDrive.Attrib.Model=StripCRLF(ReadFile("#DrivePath#/device/model",""))>
		<CFSET CurrDrive.Attrib.Vendor=StripCRLF(ReadFile("#DrivePath#/device/vendor",""))>
		<CFSET CurrDrive.Attrib.Serial=StripCRLF(ReadFile("#DrivePath#/device/serial",""))>
		<CFSET CurrDrive.Attrib.Rev=StripCRLF(ReadFile("#DrivePath#/device/firmware_rev",""))>
		<CFSET CurrDrive.Attrib.Size.BlockCount=StripCRLF(ReadFile("#DrivePath#/size","0"))>
		<CFSET CurrDrive.Attrib.Configuration.SectorSize=StripCRLF(ReadFile("#DrivePath#/queue/hw_sector_size",""))>
		<CFSET CurrDrive.Attrib.Configuration.LogicalSectorSize=StripCRLF(ReadFile("#DrivePath#/queue/logical_block_size",""))>
		<CFSET CurrDrive.Attrib.IDs.NGID=StripCRLF(ReadFile("#DrivePath#/ngid",""))>
		<CFSET CurrDrive.Attrib.IDs.NSID=StripCRLF(ReadFile("#DrivePath#/nsid",""))>
		<CFSET CurrDrive.Attrib.IDs.UUID=StripCRLF(ReadFile("#DrivePath#/uuid",""))>
		<CFSET CurrDrive.Attrib.IDs.WWID=StripCRLF(ReadFile("#DrivePath#/wwid",""))>

		<!--- Find the PCI ID of the drive's controller --->
		<CFFILE action="write" file="#PersistDir#/#exe()#_ls_-l_DrivePath_device_exec.txt" output="/bin/ls -l #DrivePath#/device/" addnewline="NO" mode="666">
		<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
		<cfexecute name="/bin/ls" arguments="-l #DrivePath#/device/" variable="tmp"  timeout="90" />
		<CFFILE action="write" file="#PersistDir#/#exe()#_ls_-l_DrivePath_device.txt" output="#tmp#" addnewline="NO" mode="666">
		<!--- <cfoutput>#DrivePath#/device/<pre>#tmp#</pre></cfoutput> --->
		<CFSET Key="">
		<CFLOOP index="i" list="#tmp#" delimiters="#Chr(10)#">
			<CFIF FindNoCase("device ->",i)>
				<CFSET CurrDrive.ControllerPCID=ListLast(i,"/")>
				<CFSET Key=CurrDrive.ControllerPCID>
				<CFBREAK>
			</CFIF>
		</CFLOOP>
		<CFIF Key EQ "">
			<CFLOOP index="i" from="#ListLen(DrivePath,"/")#" to="4" step="-1">
				<CFSET CheckKey=ListGetAt(DrivePath,i,"/")>
				<CFTRY>
					<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_-D_-s_#SanitizeFN(CheckKey)#_exec.txt" output="/usr/bin/lspci -D -s #CheckKey#" mode="666" addnewline="NO">
					<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
					<cfexecute name="/usr/bin/lspci" arguments="-D -s #CheckKey#" timeout="300" variable="lspci" />
					<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_-D_-s_#SanitizeFN(CheckKey)#.txt" output="#lspci#" mode="666" addnewline="NO">
					<CFSET Key=CheckKey>
					<CFSET CurrDrive.ControllerPCID=CheckKey>
					<CFBREAK>
				<CFCATCH Type="Any">
					<!--- Eat any errors --->
				</CFCATCH>
				</CFTRY>
			</CFLOOP>
		</CFIF>
		<CFSET ControllerPath=DrivePath>
		<CFSET OK=0>
		<CFLOOP condition="NOT OK">
			<CFIF ListLast(ControllerPath,"/") EQ Key>
				<CFSET OK=1>
			<CFELSE>
				<CFSET ControllerPath=ListDeleteAt(ControllerPath,ListLen(ControllerPath,"/"),"/")>
			</CFIF>
		</CFLOOP>
		<CFIF StructKeyExists(HW,Key) EQ "NO">
			<CFSET HW[Key]=Duplicate(BlankController)>
			<CFSET HW[Key].Path=ControllerPath>
			<!--- Get the controller information --->
			<CFSET tmpbus=Replace(Key,":","-","ALL")>
			<CFIF tmpbus EQ "">
				<CFOUTPUT>
				#TS()# Error: Unable to identify a system bus.<br>
				<CFSET ErrorFlag=1>
				<CFSET ErrorReason=ListAppend(ErrorReason,"Unable to idnetify a system bus. Info: #CurrLine#","|")>
				</CFOUTPUT>
				<CFBREAK>
			</CFIF>
			<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vmm-s_#tmpbus#_exec.txt" output="/usr/bin/lspci -vmm -s #Key#" addnewline="NO" mode="666">
			<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
			<CFTRY>
				<cfexecute name="/usr/bin/lspci" arguments="-vmm -s #Key#" timeout="300" variable="lspci" />
				<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vmm_#tmpbus#.txt" output="#lspci#" addnewline="NO" mode="666">
				<CFLOOP index="CLine" list="#lspci#" delimiters="#Chr(10)#">
					<CFSET Resource=ListFirst(CLine,":")>
					<CFSET ResourceList=Trim(Replace(ListDeleteAt(CLine,1,":"),Chr(9),"","ALL"))>
					<CFSET HW[Key].Config[Resource]=ResourceList>
				</CFLOOP>
				<CFSET tmpbus=Replace(Key,":","-","ALL")>
			<CFCATCH Type="Any">
				<CFSET tmpbus="">
				<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vmm_#tmpbus#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
			</CFCATCH>
			</CFTRY>
			<CFIF tmpbus NEQ "">
				<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vv-s_#tmpbus#_exec.txt" output="/usr/bin/lspci -vv -s #Key#" addnewline="NO" mode="666">
				<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
				<cfexecute name="/usr/bin/lspci" arguments="-vv -s #Key#" timeout="300" variable="lspci" />
				<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vv-s_#tmpbus#.txt" output="#lspci#" addnewline="NO" mode="666">
				<CFLOOP index="CLine" list="#lspci#" delimiters="#Chr(10)#">
					<CFSET Resource=Trim(ListFirst(CLine,":"))>
					<CFSET ResourceList=Trim(Replace(ListDeleteAt(CLine,1,":"),Chr(9),"","ALL"))>
					<CFIF ListFindNoCase("LnkCap,LnkSta",Resource)>
						<CFLOOP index="tmp2" list="#ResourceList#">
							<CFSET tmp3=Trim(tmp2)>
							<CFIF ListFirst(tmp3," ") EQ "Speed">
								<CFSET HW[Key].Config[Resource].Speed=ListGetAt(tmp3,2," ")>
							</CFIF>
							<CFIF ListFirst(tmp3," ") EQ "Width">
								<CFSET HW[Key].Config[Resource].Width=ListGetAt(tmp3,2," ")>
							</CFIF>
						</CFLOOP>
					</CFIF>
				</CFLOOP>
				<CFIF HW[Key].Config.LnkCap.Speed NEQ "">
					<CFIF ListFindNoCase("x1,x2,x4,x8,x16,x32",HW[Key].Config.LnkCap.Width)>
						<CFQUERY name="SpeedInfo" dbtype="Query">
							SELECT *, #HW[Key].Config.LnkCap.Width# AS Throughput
							FROM LinkSpeed
							WHERE TransferRate='#Val(HW[Key].Config.LnkCap.Speed)#'
						</CFQUERY>
						<CFIF SpeedInfo.RecordCount EQ 1>
							<CFSET MB=Val(SpeedInfo.Throughput)>
							<CFIF Find("GB/s",SpeedInfo.Throughput)>
								<CFSET MB=MB * 1000>
							</CFIF>
							<CFSET HW[Key].Config.LnkCap.PCIeVer=SpeedInfo.PCIeVer>
							<CFSET HW[Key].Config.LnkCap.Throughput=SpeedInfo.Throughput>
							<CFSET HW[Key].Config.LnkCap.ThroughputMB=MB>
							<CFSET HW[Key].Config.LnkCap.LineCodeL=SpeedInfo.LineCodeL>
							<CFSET HW[Key].Config.LnkCap.LineCodeH=SpeedInfo.LineCodeH>
							<CFSET HW[Key].Config.LnkCap.OverheadMB=MB - MB * (SpeedInfo.LineCodeL / SpeedInfo.LineCodeH)>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFIF>
			<!--- Get parent device tree down to the root hub --->

			<CFLOOP index="i" from="3" to="#ListLen(DrivePath,"/")#">
				<CFSET CheckKey=ListGetAt(DrivePath,i,"/")>
				<CFIF CheckKey EQ Key>
					<CFBREAK>
				</CFIF>
				<CFIF Left(CheckKey,3) EQ "pci">
					<CFSET CheckKey=Mid(CheckKey,4,99)>
				</CFIF>
				<CFIF ListLen(CheckKey,":") EQ 2>
					<CFSET CheckKey=CheckKey & ":00.0">
				</CFIF>
				<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_CheckKey_exec.txt" output="/usr/bin/lspci -D -s #CheckKey#" addnewline="NO" mode="666">
				<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
				<CFTRY>
					<cfexecute name="/usr/bin/lspci" arguments="-D -s #CheckKey#" timeout="300" variable="lspci" />
					<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_CheckKey.txt" output="#lspci#" addnewline="NO" mode="666">
					<CFIF Left(lspci,5) NEQ "lspci">
						<CFSET NR=ArrayLen(HW[Key].Parents)+1>
						<CFSET HW[Key].Parents[NR]=ArrayNew(1)>
						<CFSET HW[Key].Parents[NR][1]=CheckKey>
						<CFSET HW[Key].Parents[NR][2]=ListDeleteAt(lspci,1," ")>
					</CFIF>
				<CFCATCH Type="Any">
					<CFFILE action="write" file="#PersistDir#/#exe()#_lspci_CheckKey_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
				</CFCATCH>
				</CFTRY>
			</CFLOOP>

		</CFIF>

		<CFSET PortNo=ArrayLen(HW[Key].Ports) + 1>
		<CFSET HW[Key].Ports[PortNo]=Duplicate(CurrDrive)>
		<CFSET HW[Key].TotalDrives=HW[Key].TotalDrives + 1>

	</CFIF>
</CFLOOP>

<!--- Identify drive ports --->
<CFFILE action="write" file="/tmp/DiskSpeedTmp/tmp.sh" mode="766" output="/usr/bin/find /sys/devices/pci* -xtype f -name port*" addnewline="no">
<CFFILE action="write" file="#PersistDir#/#exe()#_findports_exec.txt" output="/usr/bin/find /sys/devices/pci* -xtype f -name port*" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<CFTRY>
	<cfexecute name="/tmp/DiskSpeedTmp/tmp.sh" timeout="300" variable="Path" />
	<CFFILE action="write" file="#PersistDir#/#exe()#_findports.txt" output="#Path#" mode="666">
<CFCATCH Type="Any">
	<CFFILE action="write" file="#PersistDir#/#exe()#_findports_error.txt" output="#CFCATCH.Message# #CFCATCH.Detail#" mode="666">
	<CFSET ErrorFlag=1>
	<CFSET Path="">
	<CFSET ErrorReason=ListAppend(ErrorReason,"Finding PCI ports","|")>
</CFCATCH>
</CFTRY>

<!--- Debug path port numbers --->
<CFLOOP index="CurrLine" list="#Path#" delimiters="#Chr(10)#">
	<CFTRY>
		<CFFILE action="read" file="#CurrLine#" variable="PortNo">
		<CFFILE action="append" file="#PersistDir#/findports.txt" output="#CurrLine# = [#StripCRLF(PortNo)#]" mode="666">
	<CFCATCH Type="Any">
		<CFFILE action="append" file="#PersistDir#/findports.txt" output="#CurrLine# = [Error reading file]" mode="666">
	</CFCATCH>
	</CFTRY>
</CFLOOP>
<!--- <cfoutput><pre>#path#</pre></cfoutput> --->
<CFLOOP index="CurrPath" list="#Path#" delimiters="#Chr(10)#">
	<!--- Find controller in path --->
	<CFSET ControllerLoc=0>
	<CFSET x=0>
	<CFLOOP index="PathSpot" list="#CurrPath#" delimiters="/">
		<CFSET x=x+1>
		<CFIF REFindNoCase("[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}.[0-9a-f]",PathSpot) GT 0>
			<CFSET ControllerLoc=x>
		</CFIF>
	</CFLOOP>
	<CFIF ControllerLoc GT 0>
		<CFSET DrivePath="">
		<CFSET ControllerLoc=ControllerLoc + 1>
		<CFLOOP index="i" from="1" to="#ControllerLoc#">
			<CFSET DrivePath=ListAppend(DrivePath,ListGetAt(CurrPath,i,"/"),"/")>
		</CFLOOP>
		<CFSET DrivePath="/" & DrivePath & "/">
		<!--- We've got the path for the controller, find it in the HW scope --->
		<CFSET OK=0>
		<CFLOOP index="Key" list="#StructKeyList(HW)#">
			<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
				<CFIF Left(HW[Key].Ports[PortNo].DevicePath,Len(DrivePath)) EQ DrivePath>
					<CFFILE action="read" file="#CurrPath#" variable="DrivePort">
					<CFSET HW[Key].Ports[PortNo].PortNo=StripCRLF(DrivePort)>
					<CFSET OK=1>
					<CFBREAK>
				</CFIF>
			</CFLOOP>
			<CFIF OK>
				<CFBREAK>
			</CFIF>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<!--- Identify total ATA ports on controllers --->
<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/findports_hw.json" output="#json#" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFDIRECTORY action="list" directory="#HW[Key].Path#" type="dir" filter="ata*" name="tmp">
	<CFSET HW[Key].TotalPorts=tmp.RecordCount>
	<CFSET tmpkey=Replace(Key,":","-","ALL")>
	<CFSET json=SerializeJSON(tmp)>
	<CFFILE action="write" file="#PersistDir#/debug/findports_atadir_#tmpkey#.json" output="#json#" addnewline="NO" mode="666">
</CFLOOP>

<!--- Flag controllers as USB controllers if they have USB drives attached to them --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 1>
				<CFFILE action="append" file="#PersistDir#/debug/findports.txt" output="Controller [#Key#] flagged as a USB controller">
				<CFSET HW[Key].USB=1>
				<CFBREAK>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- If no PortNo found, assign it to the current array number --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF HW[Key].USB EQ 0>
		<CFSET AssignedPorts="">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF IsNumeric(HW[Key].Ports[PortNo].PortNo)>
					<CFSET AssignedPorts=ListAppend(AssignedPorts,HW[Key].Ports[PortNo].PortNo)>
				</CFIF>
			</CFIF>
		</CFLOOP>
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF IsNumeric(HW[Key].Ports[PortNo].PortNo)>
					<CFFILE action="append" file="#PersistDir#/findports.txt" output="Controller [#Key#] Array [#PortNo#] already assigned to port [#HW[Key].Ports[PortNo].PortNo#]">
				<CFELSE>
					<!--- Find an empty port number --->
					<CFLOOP index="i" from="1" to="999">
						<CFIF ListFind(AssignedPorts,i) EQ "NO">
							<CFSET HW[Key].Ports[PortNo].PortNo=i>
							<CFSET HW[Key].Ports[PortNo].PortNoNotFound=1>
							<CFSET AssignedPorts=ListAppend(AssignedPorts,i)>
							<CFFILE action="append" file="#PersistDir#/findports.txt" output="Controller [#Key#] Array [#PortNo#] not assigned, assigned to port [#HW[Key].Ports[PortNo].PortNo#]">
							<CFBREAK>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<!--- Assign drives to correct port number and fill in blanks --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFFILE action="append" file="#PersistDir#/findports.txt" output="Processing Key [#Key#] - TotalPorts: [#HW[Key].TotalPorts#] Ports Count: [#ArrayLen(HW[Key].Ports)#] USB: [#HW[Key].USB#]">
	<CFIF HW[Key].TotalPorts LT ArrayLen(HW[Key].Ports)>
		<CFFILE action="append" file="#PersistDir#/findports.txt" output="TotalPorts less than port array count, adjusted">
		<CFSET HW[Key].TotalPorts=ArrayLen(HW[Key].Ports)>
	</CFIF>
	<CFIF HW[Key].TotalPorts GT 0 AND HW[Key].USB EQ 0>
		<CFSET NewPorts=ArrayNew(1)>
		<!--- init --->
		<CFFILE action="append" file="#PersistDir#/findports.txt" output="Creating empty drive array with [#HW[Key].TotalPorts#] ports">
		<CFLOOP index="i" from="1" to="#HW[Key].TotalPorts#">
			<CFSET NewPorts[i]=Duplicate(Drive)>
		</CFLOOP>
		<!--- Assign --->
		<CFLOOP index="i" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF Val(HW[Key].Ports[i].PortNo) GT 0>
				<CFFILE action="append" file="#PersistDir#/findports.txt" output="Moving row [#i#] to row [#HW[Key].Ports[i].PortNo#]">
				<CFSET NewPorts[HW[Key].Ports[i].PortNo]=Duplicate(HW[Key].Ports[i])>
			<CFELSE>
				<CFFILE action="append" file="#PersistDir#/findports.txt" output="Moving row [#i#] to row [#HW[Key].Ports[i].PortNo#] - Skipped, invalid PortNo">
			</CFIF>
		</CFLOOP>
		<!--- Replace --->
		<CFSET HW[Key].Ports=Duplicate(NewPorts)>
		<CFFILE action="append" file="#PersistDir#/findports.txt" output="New drive port array assigned with [#ArrayLen(NewPorts)#] ports">
	</CFIF>
</CFLOOP>

<!--- Remove any drives that were previously removed (such as floppy drives) but re-added during bus scan --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF ListFindNoCase(DeviceIDsToRemove,HW[Key].Ports[PortNo].DriveID)>
			<CFSET HW[Key].Ports[PortNo]["DriveID"]="">
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFFILE action="write" file="#PersistDir#/HideDriveIDs.txt" output="#DeviceIDsToRemove#" addnewline="NO" mode="666">

<!--- Remove empty controllers after last step --->
<CFSET KeysToRemove="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFSET DrivesFound=0>
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFSET DrivesFound=1>
			<CFBREAK>
		</CFIF>
	</CFLOOP>
	<CFIF DrivesFound EQ 0>
		<CFSET KeysToRemove=ListAppend(KeysToRemove,Key)>
	</CFIF>
</CFLOOP>
<CFIF KeysToRemove NEQ "">
	<CFLOOP index="CurrKey" list="#KeysToRemove#">
		<CFSET StructDelete(HW,CurrKey)>
	</CFLOOP>
</CFIF>


<!--- Get drive hardware attributes --->
<CFFILE action="write" file="#PersistDir#/#exe()#_lshw-c_disk_exec.txt" output="/usr/bin/lshw -c disk" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/usr/bin/lshw" arguments="-c disk" timeout="300" variable="DiskInfo" />
<CFFILE action="write" file="#PersistDir#/#exe()#_lshw_disk.txt" output="#DiskInfo#" addnewline="NO" mode="666">
<CFSET DiskInfo=DiskInfo & "*">
<CFSET Disks=REMatch("-disk[\d\w\s\D\W\S]*?\*",DiskInfo)>
<CFLOOP index="CR" from="1" to="#ArrayLen(Disks)#">
	<CFSET Info=ListToArray(Disks[CR],Chr(10))>
	<CFSET E=ArrayLen(Info) - 1>
	<CFSET Attribs=StructNew()>
	<CFSET Attribs["logical name"]="">
	<CFLOOP index="i" from="2" to="#E#">
		<CFSET Desc=Trim(ListFirst(Info[i],":"))>
		<CFSET DescVal=Trim(ListDeleteAt(Info[i],1,":"))>
		<CFSET Attribs[Desc]=DescVal>
	</CFLOOP>
	<CFIF StructKeyExists(Attribs,"configuration")>
		<CFSET tmp=StructNew()>
		<CFLOOP index="CurrItem" list="#Attribs.configuration#" delimiters=" ">
			<CFSET i=Trim(ListFirst(CurrItem,"="))>
			<CFSET v=Trim(ListLast(CurrItem,"="))>
			<CFSET tmp[i]=v>
		</CFLOOP>
		<CFSET Attribs.configuration=Duplicate(tmp)>
	</CFIF>
	<CFIF StructKeyExists(Attribs,"size")>
		<CFSET tmp=StructNew()>
		<CFSET tmp.gib=Val(ListFirst(Attribs.size," "))>
		<CFSET tmp.Size=ListLast(Attribs.size," ")>
		<CFSET tmp.Size=Mid(tmp.Size,2,Len(tmp.Size)-2)>
		<CFIF Right(tmp.Size,2) EQ "GB" AND Len(tmp.Size) GT 5>
			<CFSET tmp.DispSize=Trim(NumberFormat(Val(tmp.Size)/1000,"999.9"))>
			<CFIF Right(tmp.DispSize,2) EQ ".0">
				<CFSET tmp.DispSize=Int(tmp.DispSize) & "TB">
			<CFELSE>
				<CFSET tmp.DispSize=tmp.DispSize & "TB">
			</CFIF>
		<CFELSE>
			<CFSET tmp.DispSize=tmp.Size>
		</CFIF>
		<CFSET Attribs.Size=Duplicate(tmp)>
	<CFELSE>
		<CFSET Attribs.Size=StructNew()>
		<CFSET Attribs.Size.gib=0>
		<CFSET Attribs.Size.Size=0>
	</CFIF>
	<!--- Find drive --->
	<CFIF Attribs["logical name"] NEQ "">
		<CFSET Break=0>
		<CFLOOP index="Key" list="#StructKeyList(HW)#">
			<CFSET CheckID=ListLast(Attribs["logical name"],"/")>
			<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
				<CFIF CheckID EQ HW[Key].Ports[PortNo].DriveID>
					<CFLOOP index="CurrKey" list="#StructKeyList(Attribs)#">
						<CFIF CurrKey EQ "Size">
							<CFLOOP index="CurrKey2" list="#StructKeyList(Attribs.Size)#">
								<CFSET HW[Key].Ports[PortNo].Attrib.Size[CurrKey2]=Attribs.Size[CurrKey2]>
							</CFLOOP>
						<CFELSE>
							<CFSET HW[Key].Ports[PortNo].Attrib[CurrKey]=Attribs[CurrKey]>
						</CFIF>
					</CFLOOP>
					<CFSET Break=1>
				</CFIF>
				<CFIF Break>
					<CFBREAK>
				</CFIF>
			</CFLOOP>
			<CFIF Break>
				<CFBREAK>
			</CFIF>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<!--- Get drive information for NVME drives using nvmi-cli --->
<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_list_exec.txt" output="/usr/sbin/nvme list" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/usr/sbin/nvme" arguments="list" timeout="300" variable="DiskInfo" />
<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_list.txt" output="#DiskInfo#" addnewline="NO" mode="666">
<CFIF Trim(StripCRLF(DiskInfo)) NEQ "">
	<CFSET DiskInfo=FlatFileToQuery(DiskInfo)>
	<CFLOOP index="CF" from="1" to="#DiskInfo.RecordCount#">
		<CFLOOP index="Key" list="#StructKeyList(HW)#">
			<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
				<CFIF HW[Key].Ports[PortNo].DevicePath NEQ "" AND HW[Key].Ports[PortNo].DriveID EQ ListLast(DiskInfo.Node[CF],"/")>
					<CFIF FindNoCase(ListLast(HW[Key].Ports[PortNo].DevicePath,"/"),DiskInfo.Node[CF])>
						<CFSET HW[Key].TotalDrives=HW[Key].TotalDrives + 1>
						<CFSET HW[Key].NVMe=1>
						<!--- <CFSET HW[Key].Ports[PortNo].DriveID=ListLast(DiskInfo.Node[CF],"/")> --->
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=DiskInfo.Model[CF]>
						<CFSET HW[Key].Ports[PortNo].Attrib.Serial=DiskInfo.SN[CF]>
						<CFSET HW[Key].Ports[PortNo].Attrib.Rev=DiskInfo["FW Rev"][CF]>
						<cfscript>
						SectorSize=Val(ListGetAt(DiskInfo.Format[CF],1," "));
						SizeInd=ListGetAt(DiskInfo.Format[CF],2," ");
						if (SizeInd EQ "KB") SectorSize=SectorSize * 1000;
						if (SizeInd EQ "KiB") SectorSize=SectorSize * 1024;
						if (ListLen(DiskInfo.Format[CR]," ") GT 2) {
							if (ListGetAt(DiskInfo.Format[CR],3," ") EQ "+") {
								SectorSize2=Val(ListGetAt(DiskInfo.Format[CF],4," "));
								SizeInd=ListGetAt(DiskInfo.Format[CF],5," ");
								if (SizeInd EQ "KB") SectorSize2=SectorSize2 * 1000;
								if (SizeInd EQ "KiB") SectorSize2=SectorSize2 * 1024;
								SectorSize=SectorSize + SectorSize2;
							}
						}
						</cfscript>
						<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize=SectorSize>
						<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.SectorSize=SectorSize>

						<!--- Controller info --->
						<CFSET ControllerNode="/dev/" & Left(ListLast(DiskInfo.Node[CF],'/'),5)>
						<CFSET ControllerNode2=Replace(ControllerNode,"/","_","ALL")>
						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ctrl_#ControllerNode2#_exec.txt" output="/usr/sbin/nvme id-ctrl #ControllerNode#" addnewline="NO" mode="666">
						<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
						<CFTRY>
							<CFEXECUTE name="/usr/sbin/nvme" arguments="id-ctrl #ControllerNode#" timeout="300" variable="Info" />
							<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ctrl_#ControllerNode2#.txt" output="#Info#" addnewline="NO" mode="666">
							<CFSET Info=ColumnsToStruct(Info)>
							<!--- https://news.ycombinator.com/item?id=13350218 --->
							<CFSET HW[Key].Ports[PortNo].Attrib.MDTS=Info.MDTS>
						<CFCATCH Type="Any">
							<CFSET Info="">
							<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ctrl_#ControllerNode2#_Error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
						</CFCATCH>
						</CFTRY>

						<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ns_#ListLast(DiskInfo.Node[CF],'/')#_exec.txt" output="/usr/sbin/nvme id-ns #DiskInfo.Node[CF]#" addnewline="NO" mode="666">
						<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
						<CFTRY>
							<CFEXECUTE name="/usr/sbin/nvme" arguments="id-ns #DiskInfo.Node[CF]#" timeout="300" variable="Info" />
							<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ns_#ListLast(DiskInfo.Node[CF],'/')#.txt" output="#Info#" addnewline="NO" mode="666">
							<CFSET Info=ColumnsToStruct(Info)>
							<CFSET HW[Key].Ports[PortNo].Attrib.Size.Size=InputBaseN(ListLast(Info.ncap,"x"),16)>
							<CFLOOP index="CurrKey" list="#StructKeyList(Info)#">
								<CFIF Left(CurrKey,5) EQ "lbaf ">
									<CFIF Find("(in use)",Info[CurrKey])>
										<CFSET lbaf=REMatchNoCase("lbads:\d*",Info[CurrKey])>
										<CFSET HW[Key].Ports[PortNo].Attrib.LBADS=ListLast(lbaf[1],":")>
									</CFIF>
								</CFIF>
							</CFLOOP>
						<CFCATCH Type="Any">
							<CFSET Info="">
							<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_id-ns_#ListLast(DiskInfo.Node[CF],'/')#_Error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
						</CFCATCH>
						</CFTRY>

						<!--- Compute optimal block size for NVME drives --->
						<CFIF HW[Key].Ports[PortNo].Attrib.MDTS GT 0 AND HW[Key].Ports[PortNo].Attrib.LBADS GT 0>
							<CFSET HW[Key].Ports[PortNo].OptimalBlockSize=2^HW[Key].Ports[PortNo].Attrib.MDTS * 2^HW[Key].Ports[PortNo].Attrib.LBADS>
						</CFIF>

						<!--- "nvme show-regs" can cause a system hang on some hardware. Maiwo KT015 (Silicon Motion, Inc. SM2263EN/SM2263XT SSD Controller (rev 03))
						Replacing with nvme id-ns
						<CFIF Info NEQ "">
							<CFSET Info=ColumnsToStruct(Info)>
							<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.BlockCount=InputBaseN(ListLast(Info.nsze,"x"),16)>
							<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_show-regs_#ListLast(DiskInfo.Node[CF],'/')#_exec.txt" output="/usr/sbin/nvme show-regs #DiskInfo.Node[CF]#" addnewline="NO" mode="666">
							<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
							<CFTRY>
								<CFEXECUTE name="/usr/sbin/nvme" arguments="show-regs #DiskInfo.Node[CF]#" timeout="300" variable="Info" />
								<CFFILE action="write" file="#PersistDir#/#exe()#_nvme_show-regs_#ListLast(DiskInfo.Node[CF],'/')#.txt" output="#Info#" addnewline="NO" mode="666">
								<CFSET Info=ColumnsToStruct(Info)>
								<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.NVMeVer=Val(Left(Info.version,1) & "." & Mid(Info.version,2,99))>
							<CFCATCH Type="Any">
								<CFFILE action="write" file="#PersistDir#/#exe()#nvme_show-regs_#ListLast(DiskInfo.Node[CF],'/')#_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
								<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.NVMeVer="Unknown">
							</CFCATCH>
							</CFTRY>
						</CFIF>
						--->
						<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.RPM="Solid State Device">

						<CFSET HW[Key].Ports[PortNo].Attrib.Size.Bytes=HW[Key].Ports[PortNo].Attrib.Configuration.BlockCount * HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize>
						<CFSET tmp=KBytes(HW[Key].Ports[PortNo].Attrib.Size.Bytes)>
						<CFSET HW[Key].Ports[PortNo].Attrib.Size.DispSize=Int(ListFirst(tmp," ")) & ListLast(tmp," ")>
					</CFIF>
				</CFIF>
			</CFLOOP>
		</CFLOOP>
	</CFLOOP>
</CFIF>

<CFOUTPUT>#TS()# Scanning storage controllers<br></CFOUTPUT><CFFLUSH>
<CFFILE action="write" file="#PersistDir#/#exe()#_lshw_exec.txt" output="/usr/bin/lshw c storage" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/usr/bin/lshw" arguments="-c storage" timeout="300" variable="Controllers" />
<CFFILE action="write" file="#PersistDir#/#exe()#_lshw.txt" output="#Controllers#" addnewline="NO" mode="666">
<CFSET CurrController=Duplicate(BlankControllerConfig)>
<CFSET ck=0>
<CFLOOP index="line" list="#Controllers#" delimiters="#Chr(10)#">
	<CFSET CurrLine=Trim(line)>
	<CFIF Left(CurrLine,2) EQ "*-">
		<!--- <CFIF ListLen(StructKeyList(CurrController)) GT 1> --->
		<CFIF CK EQ 1>
			<CFIF ListFindNoCase("ide,storage,scsi,usb,serial",CurrControllerType) GT 0>
				<CFIF StructKeyExists(CurrController,"bus info")>
					<CFSET Bus=ListGetAt(CurrController["bus info"],2,"@")>
					<CFIF StructKeyExists(HW,Bus) EQ "NO">
						<CFSET HW[Bus]=Duplicate(BlankController)>
					</CFIF>
					<!--- Parse out configuration block --->
					<CFIF StructKeyExists(CurrController,"configuration")>
						<CFSET tmp=StructNew()>
						<CFLOOP index="item" list="#CurrController.configuration#" delimiters=" ">
							<CFSET Key=ListFirst(item,"=")>
							<CFSET KeyVal=Trim(ListDeleteAt(item,1,"="))>
							<CFSET tmp[Key]=KeyVal>
						</CFLOOP>
						<CFSET CurrController.Config.configuration=Duplicate(tmp)>
					</CFIF>
					<!--- Parse out resource block --->
					<CFIF StructKeyExists(CurrController,"resources")>
						<CFSET tmp=StructNew()>
						<CFLOOP index="item" list="#CurrController.resources#" delimiters=" ">
							<CFSET Key=ListFirst(item,":")>
							<CFSET KeyVal=Trim(ListDeleteAt(item,1,":"))>
							<CFSET tmp[Key]=KeyVal>
						</CFLOOP>
						<CFSET CurrController.Config.resources=Duplicate(tmp)>
					</CFIF>
					<!--- Locate the directory representing the controller --->
					<CFDIRECTORY action="list" directory="/sys/devices" type="dir" filter="pci*" name="sysdir">
					<CFLOOP index="sysdiridx" from="1" to="#sysdir.RecordCount#">
						<CFSET Args='"/sys/devices/#sysdir.Name[sysdiridx]#" -name "#Bus#"'>
						<CFFILE action="write" file="#PersistDir#/#exe()#_find_controller_dir_exec.txt" output="/usr/bin/find #Args#" addnewline="no" mode="666">
						<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
						<cfexecute name="/usr/bin/find" arguments="#Args#" timeout="300" variable="Path" />
						<CFFILE action="write" file="#PersistDir#/#exe()#_find_controller_dir.txt" output="#Path#" addnewline="no" mode="666">
						<CFIF Path NEQ "">
							<CFSET Loc=FindNoCase("/sys/",Path,2)>
							<CFIF Loc GT 0>
								<CFSET Path=Mid(Path,Loc,Len(Path))>
							</CFIF>
							<CFSET CurrController.Path=StripLF(Path)>
							<CFSET tmp=REMatchNoCase("[0-9a-z]{2,4}:[0-9a-z]{2}:[0-9a-z]{2}.[0-9a-z]",CurrController.Path)>
							<CFSET CurrController.PCISlot="">
							<CFIF ArrayLen(tmp) EQ 1>
								<CFSET CurrController.PCISlot=tmp[1]>
							<CFELSEIF ArrayLen(tmp) GT 1>
								<CFSET CurrController.PCISlot=tmp[ArrayLen(tmp)-1]>
							</CFIF>
							<CFIF Path NEQ "">
								<!--- Fetch additional information about the controller --->
								<CFSET tmpbus=Replace(Bus,":","-","ALL")>
								<cffile action="write" file="#PersistDir#/#exe()#_lspci-vmm-s#tmpbus#_exec.txt" output="/usr/bin/lspci -vmm -s #Bus#" mode="666" addnewline="NO">
								<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
								<cfexecute name="/usr/bin/lspci" arguments="-vmm -s #Bus#" timeout="300" variable="lspci" />
								<cffile action="write" file="#PersistDir#/#exe()#_lspci-vmm-s#tmpbus#.txt" output="#lspci#" mode="666" addnewline="NO">
								<CFLOOP index="CLine" list="#lspci#" delimiters="#Chr(10)#">
									<CFSET Resource=ListFirst(CLine,":")>
									<CFSET ResourceList=Trim(Replace(ListDeleteAt(CLine,1,":"),Chr(9),"","ALL"))>
									<CFSET CurrController[Resource]=ResourceList>
								</CFLOOP>
								<CFSET tmpbus=Replace(Bus,":","-","ALL")>
								<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vv-s_#tmpbus#_exec.txt" output="/usr/bin/lspci -vv -s #Bus#" addnewline="NO" mode="666">
								<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
								<cfexecute name="/usr/bin/lspci" arguments="-vv -s #Bus#" timeout="300" variable="lspci" />
								<CFFILE action="write" file="#PersistDir#/#exe()#_lspci-vv-s_#tmpbus#.txt" output="#lspci#" addnewline="NO" mode="666">
								<CFSET CurrController["LnkCap"]=StructNew()>
								<CFSET CurrController["LnkCap"].Speed="">
								<CFSET CurrController["LnkCap"].Width="">
								<CFSET CurrController["LnkCap"].PCIeVer="">
								<CFSET CurrController["LnkCap"].Throughput="">
								<CFSET CurrController["LnkCap"].ThroughputMB="">
								<CFSET CurrController["LnkSta"]=StructNew()>
								<CFSET CurrController["LnkSta"].Speed="">
								<CFSET CurrController["LnkSta"].Width="">
								<CFSET CurrController["LnkSta"].PCIeVer="">
								<CFSET CurrController["LnkSta"].ThroughputMB="">
								<CFLOOP index="CLine" list="#lspci#" delimiters="#Chr(10)#">
									<CFSET Resource=Trim(ListFirst(CLine,":"))>
									<CFSET ResourceList=Trim(Replace(ListDeleteAt(CLine,1,":"),Chr(9),"","ALL"))>
									<CFIF ListFindNoCase("LnkCap,LnkSta",Resource)>
										<CFLOOP index="tmp2" list="#ResourceList#">
											<CFIF Left(Trim(tmp2),5) EQ "Speed">
												<CFSET CurrController[Resource].Speed=ListLast(tmp2," ")>
											</CFIF>
											<CFIF Left(Trim(tmp2),5) EQ "Width">
												<CFSET CurrController[Resource].Width=ListLast(tmp2," ")>
											</CFIF>
										</CFLOOP>
									</CFIF>
								</CFLOOP>
								<CFIF CurrController.LnkCap.Speed NEQ "">
									<CFIF ListFindNoCase("x1,x2,x4,x8,x16,x32",CurrController.LnkCap.Width)>
										<CFQUERY name="SpeedInfo" dbtype="Query">
											SELECT *, #CurrController.LnkCap.Width# AS Throughput
											FROM LinkSpeed
											WHERE TransferRate='#Val(CurrController.LnkCap.Speed)#'
										</CFQUERY>
										<CFIF SpeedInfo.RecordCount EQ 1>
											<CFSET MB=Val(SpeedInfo.Throughput)>
											<CFIF Find("GB/s",SpeedInfo.Throughput)>
												<CFSET MB=MB * 1000>
											</CFIF>
											<CFSET CurrController.LnkCap.PCIeVer=SpeedInfo.PCIeVer>
											<CFSET CurrController.LnkCap.Throughput=SpeedInfo.Throughput>
											<CFSET CurrController.LnkCap.ThroughputMB=MB>
											<CFSET CurrController.LnkCap.LineCodeL=SpeedInfo.LineCodeL>
											<CFSET CurrController.LnkCap.LineCodeH=SpeedInfo.LineCodeH>
											<CFSET CurrController.LnkCap.OverheadMB=MB - MB * (SpeedInfo.LineCodeL / SpeedInfo.LineCodeH)>
										</CFIF>
									</CFIF>
								</CFIF>
								<CFIF CurrController.LnkSta.Speed NEQ "">
									<CFIF ListFindNoCase("x1,x2,x4,x8,x16,x32",CurrController.LnkSta.Width)>
										<CFQUERY name="SpeedInfo" dbtype="Query">
											SELECT *, #CurrController.LnkSta.Width# AS Throughput
											FROM LinkSpeed
											WHERE TransferRate='#Val(CurrController.LnkSta.Speed)#'
										</CFQUERY>
										<CFIF SpeedInfo.RecordCount EQ 1>
											<CFSET MB=Val(SpeedInfo.Throughput)>
											<CFIF Find("GB/s",SpeedInfo.Throughput)>
												<CFSET MB=MB * 1000>
											</CFIF>
											<CFSET CurrController.LnkSta.PCIeVer=SpeedInfo.PCIeVer>
											<CFSET CurrController.LnkSta.Throughput=SpeedInfo.Throughput>
											<CFSET CurrController.LnkSta.ThroughputMB=MB>
											<CFSET CurrController.LnkSta.LineCodeL=SpeedInfo.LineCodeL>
											<CFSET CurrController.LnkSta.LineCodeH=SpeedInfo.LineCodeH>
											<CFSET CurrController.LnkSta.OverheadMB=MB - MB * (SpeedInfo.LineCodeL / SpeedInfo.LineCodeH)>
										</CFIF>
									</CFIF>
								</CFIF>
								<CFIF CurrController.Path NEQ "">
									<!--- Save controller --->
									<CFSET HW[Bus].Type=CurrControllerType>
									<CFSET HW[Bus].Config=Duplicate(CurrController)>
								</CFIF>
							</CFIF>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFIF>
		<!--- <CFOUTPUT><script>o('scan','Scanning storage controllers...');</script></CFOUTPUT><CFFLUSH> --->
		<CFSET CK=1>
		<CFSET CurrController=Duplicate(BlankControllerConfig)>
		<CFSET CurrControllerType=ListFirst(Mid(CurrLine,3,Len(CurrLine)),":")>
	<CFELSE>
		<CFIF ListLen(CurrLine,":") GT 1>
			<CFSET Resource=ListFirst(CurrLine,":")>
			<CFSET ResourceList=Trim(ListDeleteAt(CurrLine,1,":"))>
			<CFSET CurrController[Resource]=ResourceList>
			<CFIF Resource EQ "product">
				<!--- <CFOUTPUT><script>o('scan','Scanning storage controller (#ResourceList#)');</script></CFOUTPUT><CFFLUSH> --->
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>

<!--- Remove empty/undefined controllers --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF HW[Key].Path EQ "">
		<CFSET StructDelete(HW,Key)>
	</CFIF>
</CFLOOP>

<CFOUTPUT>#TS()# Scanning USB hubs & devices<br></CFOUTPUT><CFFLUSH>


<!--- Get blockdev info to determine optimal block size --->
<CFSET RemDrives="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF Left(DriveID,2) EQ "sr">
			<CFSET HW[Key].Ports[PortNo].CDROM=1>
			<!--- Remove CD-ROM 
			<CFSET RemDrives=ListAppend(RemDrives,"#Key#|#PortNo#")>--->
		<CFELSE>
			<CFIF DriveID NEQ "">
				<CFSET Err1=0>
				<CFTRY>
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getmaxsect_dev_#DriveID#_exec.txt" output="/sbin/blockdev --getmaxsect /dev/#DriveID#" addnewline="no" mode="666">
					<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
					<cfexecute name="/sbin/blockdev" arguments="--getmaxsect /dev/#DriveID#" timeout="300" variable="blockdev" />
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getmaxsect_dev_#DriveID#.txt" output="#blockdev#" addnewline="no" mode="666">
					<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.MaxSectorsPerRequest=Val(StripCRLF(blockdev))>
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getsize64_dev_#DriveID#_exec.txt" output="/sbin/blockdev --getsize64 /dev/#DriveID#" addnewline="no" mode="666">
					<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
				<CFCATCH Type="Any">
					<CFSET RemDrives=ListAppend(RemDrives,"#Key#|#PortNo#")>
					<CFSET Err1=1>
					<CFOUTPUT>#TS()# <span class="Red">Drive #DriveID# was added to the Host after this DiskSpeed Docker was started (restart if so) or is an empty storage device. If not true, please submit a debug file. [1]</span><br></CFOUTPUT>
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getmaxsect_dev_#DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="no" mode="666">
				</CFCATCH>
				</CFTRY>
				<CFTRY>
					<cfexecute name="/sbin/blockdev" arguments="--getsize64 /dev/#DriveID#" timeout="300" variable="blockdev" />
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getsize64_dev_#DriveID#.txt" output="#blockdev#" addnewline="no" mode="666">
					<CFSET HW[Key].Ports[PortNo].Attrib.Size.Bytes=Val(StripCRLF(blockdev))>
					<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.BlockCount=HW[Key].Ports[PortNo].Attrib.Size.Bytes / HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize>
					<CFIF HW[Key].Ports[PortNo].OptimalBlockSize EQ 0>
						<CFSET HW[Key].Ports[PortNo].OptimalBlockSize=HW[Key].Ports[PortNo].Attrib.Configuration.MaxSectorsPerRequest * HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize>
					</CFIF>
				<CFCATCH Type="Any">
					<CFSET RemDrives=ListAppend(RemDrives,"#Key#|#PortNo#")>
					<CFIF Err1 EQ 0>
						<CFOUTPUT>#TS()# <span class="Red">Drive #DriveID# was added to the Host after this DiskSpeed Docker was started (restart if so) or is an empty storage device. If not true, please submit a debug file. [2]</span><br></CFOUTPUT>
					</CFIF>
					<CFFILE action="write" file="#PersistDir#/#exe()#_blockdev_getsize64_dev_#DriveID#_error.txt" output="#CFCATCH.Detail#" addnewline="no" mode="666">
				</CFCATCH>
				</CFTRY>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFSET RemDrives=ListSort(RemDrives,"textnocase","desc")>
<CFIF RemDrives NEQ "">
	<CFLOOP index="CurrDrive" list="#RemDrives#">
		<CFSET Key=ListFirst(CurrDrive,"|")>
		<CFSET PortNo=ListLast(CurrDrive,"|")>
		<CFSET HW[Key].TotalDrives=HW[Key].TotalDrives - 1>
		<CFIF ArrayLen(HW[Key].Ports) GTE PortNo>
			<CFSET ArrayDeleteAt(HW[Key].Ports,PortNo)>
		</CFIF>
	</CFLOOP>
</CFIF>
<!--- Remove CD-ROMs from Total Drive count--->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].CDROM EQ 1>
			<CFSET HW[Key].TotalDrives=HW[Key].TotalDrives - 1>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Default OptimalBlockSize to 128K for drives unable to determine --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].OptimalBlockSize EQ 0>
				<CFSET HW[Key].Ports[PortNo].OptimalBlockSize=1310720>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Get Vendor information from Product for drives that reported as "ATA" --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF Trim(HW[Key].Ports[PortNo].Attrib.Vendor) EQ "ATA">
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=ListFirst(HW[Key].Ports[PortNo].Attrib.Product," ")>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Fetch HDPARM information on drives --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer=StructNew()>
			<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current=0>
			<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Max=0>
			<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeed=0>
			<CFSET HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeedDisp="">
			<CFTRY>
				<cffile action="write" file="#PersistDir#/#exe()#_hdparm_-I_dev_#DriveID#_exec.txt" output="/sbin/hdparm -I /dev/#DriveID#" mode="666" addnewline="no">
				<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
				<cfexecute name="/sbin/hdparm" variable="tmp" arguments="-I /dev/#DriveID#" timeout="300" />
				<cffile action="write" file="#PersistDir#/#exe()#_hdparm_-I_dev_#DriveID#.txt" output="#tmp#" mode="666" addnewline="no">
			<CFCATCH Type="Any">
				<CFSET tmp="">
			</CFCATCH>
			</CFTRY>
			<CFIF FindNoCase("Capabilities",tmp)>
				<CFLOOP index="CurrLine" list="#tmp#" delimiters="#Chr(10)#">
					<cfscript>
					Item=ListFirst(Trim(CurrLine),":");
					ItemVal=Trim(ListDeleteAt(CurrLine,1,":"));
					//writeoutput("[#item#][#itemval#]<br>");
					if (Item EQ "Model Number") HW[Key].Ports[PortNo].Attrib.Model=ItemVal;
					if (Item EQ "Serial Number") HW[Key].Ports[PortNo].Attrib.Serial=ItemVal;
					if (Item EQ "Firmware Revision") HW[Key].Ports[PortNo].Attrib.Rev=ItemVal;
					if (Item EQ "Transport") HW[Key].Ports[PortNo].Attrib.Transport=ItemVal;
					if (Item EQ "Logical  Sector size") HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize=ListFirst(ItemVal," ");
					if (Item EQ "Physical Sector size") HW[Key].Ports[PortNo].Attrib.Configuration.SectorSize=ListFirst(ItemVal," ");
					if (Item EQ "XXXXXLogical/Physical Sector size")
					{
						HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize=ListFirst(ItemVal," ");
						HW[Key].Ports[PortNo].Attrib.Configuration.SectorSize=ListFirst(ItemVal," ");
					}
					if (Item EQ "Logical Sector-0 offset") HW[Key].Ports[PortNo].Attrib.Configuration.SectorZeroOffset=ListFirst(ItemVal," ");
					if (Item EQ "Nominal Media Rotation Rate") HW[Key].Ports[PortNo].Attrib.Configuration.RPM=ItemVal;
					if (Item EQ "R/W multiple sector transfer")
					{
						ItemVal=Replace(ItemVal," ","","ALL");
						for (i=1;i LTE ListLen(ItemVal,Chr(9)); i=i+1)
						{
							tmp2=ListGetAt(ItemVal,i,Chr(9));
							HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer[ListFirst(tmp2,"=")]=ListLast(tmp2,"=");
						}
					}
					if (FindNoCase("signaling speed",Item))
					{
						Signal=ListLast(Item,"(");
						Signal=ListFirst(Signal,")");
						//writeoutput("[#signal#][#val(signal)#]<br>");
						if (Val(Signal) GT HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeed)
						{
							HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeed=Val(Signal);
							HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeedDisp=Signal;
						}
					}
					</cfscript>
				</CFLOOP>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Compute bandwidth for PCI & PCI-X devices --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFSET PCI1=ListFindNoCase(HW[Key].Config.Device,"PCI"," ")>
	<CFSET PCI2=ListFindNoCase(HW[Key].Config.Device,"PCI-X"," ")>
	<CFSET IDE=ListFindNoCase(HW[Key].Config.Device,"IDE"," ")>
	<CFSET AHCI=FindNoCase("AHCI",HW[Key].Config.Device)>
	<!--- <cfoutput>#key#[#PCI1#][#PCI2#][#IDE#][#AHCI#]<br></cfoutput> --->
	<CFIF PCI1 OR PCI2 OR IDE OR AHCI>
		<CFQUERY name="CheckSpeed" dbtype="Query">
			SELECT Speed
			FROM PCILinkSpeed
			WHERE Type=<CFIF PCI1>'PCI'</CFIF><CFIF PCI2>'PCI-X'</CFIF><CFIF IDE>'IDE'</CFIF><CFIF AHCI>'PCI'</CFIF>
			  AND Width='#Replace(Replace(HW[Key].Config.Width," ","","ALL"),"bits","bit")#'
			  AND Clock='#Replace(HW[Key].Config.Clock," ","","ALL")#'
		</CFQUERY>
		<!--- <cfdump var=#checkspeed#> --->
		<CFIF CheckSpeed.RecordCount EQ 1>
			<CFSET HW[Key].Config.PCISpeed=CheckSpeed.Speed & " MB/s">
		</CFIF>
	</CFIF>
</CFLOOP>

<CFOUTPUT>#TS()# Scanning motherboard resources<br></CFOUTPUT><CFFLUSH>

<CFFILE action="write" file="#PersistDir#/#exe()#_lshw.xml_exec.txt" output="/usr/bin/lshw -xml" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<cfexecute name="/usr/bin/lshw" arguments="-xml" timeout="300" variable="HardwareXML" />
<CFFILE action="write" file="#PersistDir#/#exe()#_lshw.xml" output="#HardwareXML#" addnewline="NO" mode="666">

<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_2_exec.txt" output="/usr/sbin/dmidecode -t 2" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>

<CFSET MiscRef.MBSerial="Unknown">
<CFTRY>
	<cfexecute name="/usr/sbin/dmidecode" arguments="-t 2" timeout="300" variable="mbdata" />
	<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_2.txt" output="#mbdata#" addnewline="NO" mode="666">
	<CFLOOP index="CurrLine" list="#mbdata#" delimiters="#Chr(10)#">
		<CFIF ListFirst(Trim(CurrLine),":") EQ "Serial Number">
			<CFSET MiscRef.MBSerial=ListLast(CurrLine,":")>
		</CFIF>
	</CFLOOP>
<CFCATCH type="Any">
	<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_2_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
</CFCATCH>
</CFTRY>

<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_9_exec.txt" output="/usr/sbin/dmidecode -t 9" addnewline="NO" mode="666">
<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
<CFTRY>
	<cfexecute name="/usr/sbin/dmidecode" arguments="-t 9" timeout="300" variable="mbdata" />
	<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_9.txt" output="#mbdata#" addnewline="NO" mode="666">
<CFCATCH type="Any">
	<CFFILE action="write" file="#PersistDir#/#exe()#_dmidecode_-t_9_error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
	<CFSET mbdata="">
</CFCATCH>
</CFTRY>
<CFSET MiscRef.PCIeSlots=StructNew()>
<CFSET Slot="Unknown">
<CFLOOP index="CurrLine" list="#mbdata#" delimiters="#Chr(10)#">
	<cfscript>
	Line=Trim(CurrLine);
	if (Line EQ "System Slot Information")
	{
		if (Slot NEQ "Unknown")
		{
			MiscRef.PCIeSlots[BusAddress]=StructNew();
			MiscRef.PCIeSlots[BusAddress].Slot=Slot;
			MiscRef.PCIeSlots[BusAddress].Type=Type;
			MiscRef.PCIeSlots[BusAddress].Length=Length;
			MiscRef.PCIeSlots[BusAddress].InUse=InUse;
		}
		Slot="Unknown";
		Type="Unknown";
		Length="Unknown";
		BusAddress="Unknown";
		InUse="Unknown";
	}
	if (ListFirst(Line,":") EQ "Designation") Slot=Mid(Trim(ListDeleteAt(Line,1,":")),5,99);
	if (ListFirst(Line,":") EQ "Type") Type=Trim(ListDeleteAt(Line,1,":"));
	if (ListFirst(Line,":") EQ "Current Usage") Trim(ListDeleteAt(Line,1,":"));
	if (ListFirst(Line,":") EQ "Length") Length=Trim(ListDeleteAt(Line,1,":"));
	if (ListFirst(Line,":") EQ "Current Usage") InUse=Trim(ListDeleteAt(Line,1,":"));
	if (ListFirst(Line,":") EQ "Bus Address") BusAddress=Trim(ListDeleteAt(Line,1,":"));
	</cfscript>
</CFLOOP>
<cfscript>
if (Slot NEQ "Unknown")
{
	MiscRef.PCIeSlots[BusAddress]=StructNew();
	MiscRef.PCIeSlots[BusAddress].Slot=Slot;
	MiscRef.PCIeSlots[BusAddress].Type=Type;
	MiscRef.PCIeSlots[BusAddress].Length=Length;
	MiscRef.PCIeSlots[BusAddress].InUse=InUse;
}
</cfscript>

<!--- Strip out any CF/LF/leading & trailing spaces & populate missing fields --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="CurrKey" list="#StructKeyList(HW[Key].Config)#">
		<CFIF IsSimpleValue(HW[Key].Config[CurrKey])>
			<CFSET HW[Key].Config[CurrKey]=StripCRLF(HW[Key].Config[CurrKey])>
		</CFIF>
	</CFLOOP>
	<cfscript>
	if (StructKeyExists(HW[Key],"NVMe") EQ "NO") HW[Key].NVMe=0;
	</cfscript>
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFLOOP index="CurrKey" list="#StructKeyList(HW[Key].Ports[PortNo].Attrib)#">
				<CFIF IsSimpleValue(HW[Key].Ports[PortNo].Attrib[CurrKey])>
					<CFSET HW[Key].Ports[PortNo].Attrib[CurrKey]=Trim(StripCRLF(HW[Key].Ports[PortNo].Attrib[CurrKey]))>
				</CFIF>
			</CFLOOP>
			<cfscript>
			if (StructKeyExists(HW[Key].Ports[PortNo],"UNRAIDSlot") EQ "NO") HW[Key].Ports[PortNo].UNRAIDSlot="";
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Model") EQ "NO") HW[Key].Ports[PortNo].Attrib.Model="Unknown";
			if (HW[Key].Ports[PortNo].Attrib.Model EQ "") HW[Key].Ports[PortNo].Attrib.Model="Unknown";
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Product") EQ "NO") HW[Key].Ports[PortNo].Attrib.Product=HW[Key].Ports[PortNo].Attrib.Model;

			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Rev") EQ "NO") HW[Key].Ports[PortNo].Attrib.Rev=0;
			if (HW[Key].Ports[PortNo].Attrib.Rev EQ "") HW[Key].Ports[PortNo].Attrib.Rev=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Version") EQ "NO") HW[Key].Ports[PortNo].Attrib.Version=HW[Key].Ports[PortNo].Attrib.Rev;

			//if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Vendor") EQ "NO") HW[Key].Ports[PortNo].Attrib.Vendor=ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ");
			//if (HW[Key].Ports[PortNo].Attrib.Vendor EQ "") HW[Key].Ports[PortNo].Attrib.Vendor=ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ");
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Vendor") EQ "NO") HW[Key].Ports[PortNo].Attrib.Vendor="Unknown";
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"PlatterCnt") EQ "NO") HW[Key].Ports[PortNo].Attrib.PlatterCnt=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"HeadCnt") EQ "NO") HW[Key].Ports[PortNo].Attrib.HeadCnt=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib,"ShortStroked") EQ "NO") HW[Key].Ports[PortNo].Attrib.ShortStroked=0;

			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"LogicalSectorSize") EQ "NO") HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"SectorSize") EQ "NO") HW[Key].Ports[PortNo].Attrib.Configuration.SectorSize=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"SectorZeroOffset") EQ "NO") HW[Key].Ports[PortNo].Attrib.Configuration.SectorZeroOffset=0;
			if (StructKeyExists(HW[Key].Ports[PortNo].Attrib.Configuration,"RPM") EQ "NO") HW[Key].Ports[PortNo].Attrib.Configuration.RPM=0;

			</cfscript>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Drive vendor cleanup --->
<!--- Fetch all vendors from HDDB --->
<CFOUTPUT>#TS()# Fetching known drive vendors from the Hard Drive Database<br></CFOUTPUT><CFFLUSH>
<CFHTTP method="GET" URL="#StrangeJourney#/diskspeed/VendorList.cfm" timeout="15" throwonerror="NO"></CFHTTP>
<CFIF CFHTTP.Status_Code EQ 200>
	<cfwddx input="#CFHTTP.FileContent#" output="AllVendors" action="wddx2cfml">
<CFELSE>
	<CFOUTPUT>#TS()# Unable to fetch information - HTTP Status Code #CFHTTP.Status_Code#<br></CFOUTPUT>
	<CFSET AllVendors=QueryNew("Vendor,Vendor2","varchar,varchar")>
	<CFIF DiskSpeedDeveloper>
		<CFOUTPUT>URL: #StrangeJourney#/diskspeed/VendorList.cfm<br></CFOUTPUT>
		<cfdump var=#cfhttp#>
	</CFIF>
</CFIF>
<!--- Match the vendor case to what we have in the database --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF StructKeyList(HW[Key].Ports[PortNo].Attrib) NEQ "">
			<CFSET Vendor=HW[Key].Ports[PortNo].Attrib.Vendor>
			<CFQUERY name="CheckVendor" dbtype="Query">
				SELECT Vendor
				FROM AllVendors
				WHERE Vendor2='#UCase(Vendor)#'
			</CFQUERY>
			<CFIF CheckVendor.RecordCount NEQ 0>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=CheckVendor.Vendor>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Check for any user defined vendor overrides --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF StructKeyExists(VendorOverride,HW[Key].Ports[PortNo].Attrib.Serial)>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=VendorOverride[HW[Key].Ports[PortNo].Attrib.Serial]>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Drive model cleanup --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF StructKeyList(HW[Key].Ports[PortNo].Attrib) NEQ "">
			<CFSET Vendor=HW[Key].Ports[PortNo].Attrib.Vendor>
			<CFIF Vendor EQ "0x1af4">
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Virtio Block Device">
				<CFSET Vendor="Virtio Block Device">
				<CFIF HW[Key].Ports[PortNo].Attrib.Model EQ "Unknown">
					<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Virtual Drive">
				</CFIF>
			</CFIF>
			<!--- DriveHash indeitifies a specific drive on a specific controller & PCI slot as each can affect speeds. --->
			<CFIF StructKeyExists(HW[Key].Ports[PortNo].Attrib,"Serial") EQ "NO">
				<CFSET HW[Key].Ports[PortNo].Attrib.Serial="N/A">
			</CFIF>
			<CFIF Left(Vendor,7) EQ "Crucial" AND Len(Vendor) GT 7>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Crucial">
				<CFSET Vendor="Crucial">
			</CFIF>
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ") EQ "Intel">
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1," ")>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Intel">
			</CFIF>
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ") EQ "WDC">
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1," ")>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Western Digital">
			</CFIF>
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ") EQ "Samsung">
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1," ")>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Samsung">
			</CFIF>
			<CFIF Left(HW[Key].Ports[PortNo].Attrib.Model,3) EQ "MKN">
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Mushkin">
			</CFIF>
			<CFIF Left(HW[Key].Ports[PortNo].Attrib.Model,3) EQ "MTFD">
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Crucial">
			</CFIF>
			<CFIF Left(HW[Key].Ports[PortNo].Attrib.Vendor,4) EQ "OCZ-">
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="OCZ">
			</CFIF>
			<CFIF REFindNoCase("CT[0-9]{3,}(B|M)[A-Z]?[0-9]{2,}SSD",HW[Key].Ports[PortNo].Attrib.Model)>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Crucial">
			</CFIF>

			<CFIF HW[Key].Ports[PortNo].Attrib.Vendor EQ HW[Key].Ports[PortNo].Attrib.Model>
				<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Unknown">
			</CFIF>

			<!--- Strip off first word of the Model if it matches the Vendor --->
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ") EQ HW[Key].Ports[PortNo].Attrib.Vendor>
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1," ")>
			</CFIF>
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"-") EQ HW[Key].Ports[PortNo].Attrib.Vendor>
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1,"-")>
			</CFIF>
			<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"_") EQ HW[Key].Ports[PortNo].Attrib.Vendor>
				<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1,"_")>
			</CFIF>

			<!--- Following cfscript copied from Radio/diskspeed/SubmitDriveCleanup.cfm --->
			<CFSET i=1>
			<CFSET DriveData[i].Vendor=HW[Key].Ports[PortNo].Attrib.Vendor>
			<CFSET DriveData[i].Model=HW[Key].Ports[PortNo].Attrib.Model>
			<CFSET DriveData[i].Revision="">
<!---
	<cfscript>
	Skip=0;
	if (ListFindNoCase("BD-RE,DVD-ROM",DriveData[i].Model)) Skip=1;
	if (DriveData[i].Revision EQ "0") Skip=1;
	if (IsUnicode(DriveData[i].Vendor & DriveData[i].Model & DriveData[i].Revision)) Skip=1;

	// Vendor Cleanup
	if (Left(DriveData[i].Vendor,2) EQ "WD") {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="Western Digital";}
	if (Left(DriveData[i].Vendor,5) EQ "C300-" OR DriveData[i].Vendor EQ "CT480") DriveData[i].Vendor="Crucial";
	if ((Left(DriveData[i].Vendor,3) EQ "HDS" AND Len(DriveData[i].Vendor) GT 3) OR DriveData[i].Vendor EQ "HL-DT-ST") DriveData[i].Vendor="Hitachi";
	if (Left(DriveData[i].Vendor,4) EQ "ASMT" OR DriveData[i].Vendor EQ "SATA" OR DriveData[i].Vendor EQ "PCIe SSD" OR DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Generic";
	if ((Left(DriveData[i].Vendor,3) EQ "HUA" OR Left(DriveData[i].Vendor,3) EQ "TPH") AND Len(DriveData[i].Vendor) GT 3);
	if (Left(DriveData[i].Vendor,3) EQ "IBM" AND Len(DriveData[i].Vendor) GT 3) DriveData[i].Vendor="IBM";
	if (Left(DriveData[i].Vendor,2) EQ "MD" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="MaxDigital";
	if (Left(DriveData[i].Vendor,6) EQ "Micron" OR Left(DriveData[i].Vendor,4) EQ "MTFD") DriveData[i].Vendor="Micron";
	if (Left(DriveData[i].Vendor,3) EQ "OCZ") DriveData[i].Vendor="OCZ";
	if (Left(DriveData[i].Vendor,5) EQ "P300-") DriveData[i].Vendor="Toshiba";
	if (DriveData[i].Vendor EQ "SK") DriveData[i].Vendor="SK hynix";
	if (Left(DriveData[i].Vendor,6) EQ "SSD2SC" OR Left(DriveData[i].Vendor,5) EQ "SSDSA") DriveData[i].Vendor="Intel";
	if (Left(DriveData[i].Vendor,2) EQ "ST" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="Seagate";
	if (DriveData[i].Vendor EQ "WD" OR DriveData[i].Vendor EQ "WDC") DriveData[i].Vendor="Western Digital";
	if (DriveData[i].Vendor EQ "WL4000GSA6454") DriveData[i].Vendor="Generic";
	if (DriveData[i].Vendor EQ "-Pretec") DriveData[i].Vendor="Pretec";
	if (DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Silicon Power";
	if (DriveData[i].Vendor EQ "APPLE" and Left(DriveData[i].Model,9) EQ "APPLE HDD" AND Mid(DriveData[i].Model,11,2) EQ "ST") {DriveData[i].Vendor=1;DriveData[i].Model=Mid(DriveData[i].Model,11,999);}

	if (DriveData[i].Vendor EQ "Western Digital" AND ListFirst(DriveData[i].Vendor," ") EQ "TOSHIBA") {DriveData[i].Vendor="Toshiba";DriveData[i].Vendor=ListDeleteAt(DriveData[i].Vendor,1," ");}

	if (ListFindNoCase("MaxDigital,Seagate,Hitachi,Toshiba,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model," ") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
	if (ListFindNoCase("Seagate,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
	if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,14) EQ "BarraCuda SSD ") DriveData[i].Model=Mid(DriveData[i].Model,15,999);
	if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,2) EQ "ST" AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
	if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "MZ" AND Mid(DriveData[i].Model,3,1) NEQ "-") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
	if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "ST") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
	if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model," ") EQ "Hitachi") {DriveData[i].Vendor="Hitachi";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
	if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model,"-") EQ "OZC") {DriveData[i].Vendor="OZC";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
	if (DriveData[i].Vendor EQ "LITEONIT") DriveData[i].Vendor="LITEON";
	if (DriveData[i].Vendor EQ "LITEON" AND Left(DriveData[i].Model,3) EQ "IT ") DriveData[i].Model=Mid(DriveData[i].Model,4,999);
	if (DriveData[i].Vendor EQ "LITEON" AND Find("mm",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
	if (DriveData[i].Vendor EQ "LITEON" AND Find("MSATA",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
	if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 1100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
	if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 5100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
	if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,13) EQ "Micron P400e-") DriveData[i].Model=Mid(DriveData[i].Model,14,999);
	if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,2) EQ "MT") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
	if (DriveData[i].Vendor EQ "SK hynix" AND ListFirst(DriveData[i].Model," ") EQ "hynix") DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");
	if (Left(DriveData[i].Model,6) EQ "Force ") DriveData[i].Vendor="Corsair";
	if (Left(DriveData[i].Model,7) EQ "HS-SSD-") DriveData[i].Vendor="Hikvision";
	if (ListFirst(DriveData[i].Model," ") EQ "WD") DriveData[i].Vendor="Western Digital";
	if (ListFirst(DriveData[i].Model," ") EQ "TEAM") {DriveData[i].Vendor="Team Group";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
	if (ListFirst(DriveData[i].Model," ") EQ "WD_BLACK") DriveData[i].Vendor="Western Digital";
	if (Find("Sk Hynix",DriveData[i].Model)) DriveData[i].Vendor="Sk hynix";
	if (DriveData[i].Vendor EQ "TEAM") DriveData[i].Vendor="Team Group";
	</cfscript>
--->
<cfscript>
Skip=0;
if (Find("BD-RE",DriveData[i].Model) OR Find("DVD-ROM",DriveData[i].Model)) Skip=1;
if (DriveData[i].Revision EQ "0") Skip=1;
if (IsUnicode(DriveData[i].Vendor & DriveData[i].Model & DriveData[i].Revision)) Skip=1;
if (FindNoCase(" Flash ",DriveData[i].Model)) Skip=1;
if (ListFindNoCase("CineRAID,Config,HW,MSATA,SATA1,SATA2,SATA3,SSD",DriveData[i].Vendor)) Skip=1;
if (Left(DriveData[i].Vendor,10) EQ "RouterNAS-") Skip=1;

// Vendor Cleanup
if (Left(DriveData[i].Vendor,2) EQ "WD") {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="Western Digital";}
if (ListFindNoCase(Left(DriveData[i].Vendor,5),"C300-,C400-") OR DriveData[i].Vendor EQ "CT480") DriveData[i].Vendor="Crucial";
if ((Left(DriveData[i].Vendor,3) EQ "HDS" AND Len(DriveData[i].Vendor) GT 3) OR DriveData[i].Vendor EQ "HL-DT-ST") DriveData[i].Vendor="Hitachi";
if (Left(DriveData[i].Vendor,4) EQ "ASMT" OR DriveData[i].Vendor EQ "SATA" OR DriveData[i].Vendor EQ "PCIe SSD" OR DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Generic";
if ((Left(DriveData[i].Vendor,3) EQ "HUA" OR Left(DriveData[i].Vendor,3) EQ "TPH") AND Len(DriveData[i].Vendor) GT 3);
if (Left(DriveData[i].Vendor,3) EQ "IBM" AND Len(DriveData[i].Vendor) GT 3) DriveData[i].Vendor="IBM";
if (Left(DriveData[i].Vendor,2) EQ "MD" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="MaxDigital";
if (Left(DriveData[i].Vendor,6) EQ "Micron" OR Left(DriveData[i].Vendor,4) EQ "MTFD") DriveData[i].Vendor="Micron";
if (Left(DriveData[i].Vendor,3) EQ "OCZ") DriveData[i].Vendor="OCZ";
if (Left(DriveData[i].Vendor,5) EQ "P300-") DriveData[i].Vendor="Toshiba";
if (DriveData[i].Vendor EQ "SK") DriveData[i].Vendor="SK hynix";
if (Left(DriveData[i].Vendor,6) EQ "SSD2SC" OR Left(DriveData[i].Vendor,5) EQ "SSDSA") DriveData[i].Vendor="Intel";
if (Left(DriveData[i].Vendor,2) EQ "ST" AND IsNumeric(Mid(DriveData[i].Vendor,3,1))) DriveData[i].Vendor="Seagate";
if (DriveData[i].Vendor EQ "WD" OR DriveData[i].Vendor EQ "WDC") DriveData[i].Vendor="Western Digital";
if (DriveData[i].Vendor EQ "WL4000GSA6454") DriveData[i].Vendor="Generic";
if (DriveData[i].Vendor EQ "-Pretec") DriveData[i].Vendor="Pretec";
if (DriveData[i].Vendor EQ "SPCC") DriveData[i].Vendor="Silicon Power";
if (Left(DriveData[i].Model,6) EQ "Force ") DriveData[i].Vendor="Corsair";
if (Left(DriveData[i].Model,7) EQ "HS-SSD-") DriveData[i].Vendor="Hikvision";
if (DriveData[i].Vendor EQ "APPLE" and Left(DriveData[i].Model,9) EQ "APPLE HDD" AND Mid(DriveData[i].Model,11,2) EQ "ST") {DriveData[i].Vendor=1;DriveData[i].Model=Mid(DriveData[i].Model,11,999);}
if (Left(DriveData[i].Vendor,8) EQ "Apacer (") {DriveData[i].Vender="Apacer";DriveData[i].Model=Mid(DriveData[i],9,9999);DriveData[i].Model=Mid(DriveData[i].Model,1,Len(DriveData[i].Model)-1);}
if (DriveData[i].Vendor EQ "Drive") {
	if (DriveData[i].Model EQ "") Skip=1;
	if (Left(DriveData[i].Model,2) EQ "WD") DriveData[i].Vendor="Western Digital";
	if (DriveData[i].Model EQ "Sabrent") {DriveData[i].Vendor="Sabrent";DriveData[i].Model="No Model ID Given";}
	if (Left(DriveData[i].Model,9) EQ "GIGABYTE ") {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=Mid(DriveData[i].Model,10,999);}
}
if (Left(DriveData[i].Vendor,9) EQ "GIGABYTE ") {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=Mid(DriveData[i].Model,10,999);}
if (Left(DriveData[i].Vendor,8) EQ "Sabrent ") {DriveData[i].Vendor="Sabrent";DriveData[i].Model=Mid(DriveData[i].Model,9,999);}

if (Left(DriveData[i].Vendor,7) EQ "KIOXIA-") {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=Mid(DriveData[i].Vendor,8,999) & " " & DriveData[i].Model;}
if (REFindNoCase("SSDPR-[A-Z0-9]+?-\d+?-",DriveData[i].Vendor)) DriveData[i].Vendor="GOODRAM";
if (REFindNoCase("TP\w\d+?GB",DriveData[i].Vendor)) {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="HGST";}
if (REFindNoCase("WL\d{4}\w{3}\d+",DriveData[i].Vendor)) {DriveData[i].Model=DriveData[i].Vendor;DriveData[i].Vendor="Unknown";}
if (ListFirst(DriveData[i].Vendor," ") EQ "TOSHIBA") {DriveData[i].Vendor="Toshiba";DriveData[i].Vendor=ListDeleteAt(DriveData[i].Vendor,1," ");}

if (ListFindNoCase("MaxDigital,Seagate,Hitachi,Toshiba,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model," ") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (ListFindNoCase("Seagate,Intel",DriveData[i].Vendor) AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,14) EQ "BarraCuda SSD ") DriveData[i].Model=Mid(DriveData[i].Model,15,999);
if (DriveData[i].Vendor EQ "Seagate" AND Left(DriveData[i].Model,2) EQ "ST" AND ListLen(DriveData[i].Model,"-") GT 1) DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "MZ" AND Mid(DriveData[i].Model,3,1) NEQ "-") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Samsung" AND Left(DriveData[i].Model,2) EQ "ST") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model," ") EQ "Hitachi") {DriveData[i].Vendor="Hitachi";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (DriveData[i].Vendor EQ "Generic" AND ListFirst(DriveData[i].Model,"-") EQ "OZC") {DriveData[i].Vendor="OZC";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (DriveData[i].Vendor EQ "LITEONIT") DriveData[i].Vendor="LITEON";
if (DriveData[i].Vendor EQ "LITEON" AND Left(DriveData[i].Model,3) EQ "IT ") DriveData[i].Model=Mid(DriveData[i].Model,4,999);
if (DriveData[i].Vendor EQ "LITEON" AND Find("mm",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (DriveData[i].Vendor EQ "LITEON" AND Find("MSATA",DriveData[i].Model)) DriveData[i].Model=ListFirst(DriveData[i].Model," ");
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 1100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,12) EQ "Micron 5100 ") DriveData[i].Model=Mid(DriveData[i].Model,13,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,13) EQ "Micron P400e-") DriveData[i].Model=Mid(DriveData[i].Model,14,999);
if (DriveData[i].Vendor EQ "Micron" AND Left(DriveData[i].Model,2) EQ "MT") DriveData[i].Model=ListFirst(DriveData[i].Model,"-");
if (DriveData[i].Vendor EQ "SK hynix" AND ListFirst(DriveData[i].Model," ") EQ "hynix") DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");

if (DriveData[i].Vendor EQ "Unknown") {
	if (DriveData[i].Model EQ "") {
		Skip=1;
	} else {
		if (ListFindNoCase("ADATA,Apacer,Corsair,KINGSTON,Netac,Patriot,PNY,Reletech,Sabrent,Seagate,XPG,ZHITAI",ListFirst(DriveData[i].Model," "))) DriveData.Vendor=ListFirst(DriveData[i].Model," ");
		//if (ListFindNoCase("Western Digital",ListFirst(DriveData[i].Model," ") & " " & ListGetAt(DriveData[i],2," "))) DriveData.Vendor=ListFirst(DriveData[i].Model," ") & " " & ListGetAt(DriveData[i],2," ");
		if (ListFirst(DriveData[i].Model," ") EQ "WD") DriveData[i].Vendor="Western Digital";
		if (ListFirst(DriveData[i].Model," ") EQ "TEAM") DriveData[i].Vendor="Team Group";
		if (ListFirst(DriveData[i].Model," ") EQ "WD_BLACK") DriveData[i].Vendor="Western Digital";
		if (Find("Sk Hynix",DriveData[i].Model)) DriveData[i].Vendor="Sk hynix";
	}
}

if (IsNumeric(Val(DriveData[i].Vendor)) AND ListFindNoCase("MB,GB,TB,PB",Right(DriveData[i].Vendor,2))) Skip=1;

if (DriveData[i].Vendor EQ "SK Hynix") DriveData[i].Vendor="SK hynix";
if (DriveData[i].Vendor EQ "gigabyte") DriveData[i].Vendor="GIGABYTE";
if (DriveData[i].Model EQ "LOGICAL VOLUME") Skip=1;

if (DriveData[i].Vendor EQ "QEMU") Skip=1;
if (ListFindNoCase("SDLF1CRR-019T-1H",DriveData[i].Vendor)) DriveData[i].Vendor='SanDisk';
if (ListFindNoCase("SSDSC2BA400G3I",DriveData[i].Vendor)) DriveData[i].Vendor='Intel';

if (ListFindNoCase("CT1000P,CT1000T,CT2000P,CT2000T",Left(DriveData[i].Vendor,7))) DriveData[i].Vendor='Crucial';
if (ListFindNoCase("CT500P,CT500T",Left(DriveData[i].Vendor,6))) DriveData[i].Vendor='Crucial';
if (ListFindNoCase("HDWG,HDWT,MG04,MG06,MG07,MG08,MG09,MG10,MQ01",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='Toshiba';
if (ListFindNoCase("MZPLJ",Left(DriveData[i].Vendor,5))) DriveData[i].Vendor='Samsung';
if (ListFindNoCase("SHGP,SHPP",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='SK hynix';
if (ListFindNoCase("SP00,SPCC",Left(DriveData[i].Vendor,4))) DriveData[i].Vendor='SK hynix';


if (Find("ADATA",DriveData[i].Vendor) AND DriveData[i].Vendor NEQ "ADATA") DriveData[i].Vendor='ADATA';
if (Left(DriveData[i].Vendor,5) EQ "Lexar" AND DriveData[i].Vendor NEQ "Lexar") DriveData[i].Vendor="Lexar";
if (ListFirst(DriveData[i].Model," ") EQ "Lexar" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Lexar";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "Fanxiang" AND DriveData[i].Vendor NEQ "Fanxiang") DriveData[i].Vendor="Fanxiang";
if (ListFirst(DriveData[i].Model," ") EQ "Fanxiang" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Fanxiang";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "GIGABYTE" AND DriveData[i].Vendor NEQ "GIGABYTE") DriveData[i].Vendor="GIGABYTE";
if (ListFirst(DriveData[i].Model," ") EQ "GIGABYTE" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="GIGABYTE";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "KingSpec" AND DriveData[i].Vendor NEQ "KingSpec") DriveData[i].Vendor="KingSpec";
if (ListFirst(DriveData[i].Model," ") EQ "KingSpec" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="KingSpec";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (ListFirst(DriveData[i].Model,"-") EQ "KingSpec" AND ListLen(DriveData[i].Model,"-" GT 1)) {DriveData[i].Vendor="KingSpec";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (Left(DriveData[i].Vendor,8) EQ "KINGSTON" AND DriveData[i].Vendor NEQ "KINGSTON") DriveData[i].Vendor="KINGSTON";
if (ListFirst(DriveData[i].Model," ") EQ "KINGSTON" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="KINGSTON";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,6) EQ "KIOXIA" AND DriveData[i].Vendor NEQ "KIOXIA") DriveData[i].Vendor="KIOXIA";
if (ListFirst(DriveData[i].Model,"-") EQ "KIOXIA" AND ListLen(DriveData[i].Model,"-" GT 1)) {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1,"-");}
if (Left(DriveData[i].Vendor,8) EQ "Memblaze" AND DriveData[i].Vendor NEQ "Memblaze") DriveData[i].Vendor="Memblaze";
if (ListFirst(DriveData[i].Model," ") EQ "Memblaze" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Memblaze";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,3) EQ "MSI" AND DriveData[i].Vendor NEQ "MSI") DriveData[i].Vendor="MSI";
if (ListFirst(DriveData[i].Model," ") EQ "MSI" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="MSI";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "Patriot" AND DriveData[i].Vendor NEQ "Patriot") DriveData[i].Vendor="Patriot";
if (ListFirst(DriveData[i].Model," ") EQ "Patriot" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Patriot";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "Sabrent" AND DriveData[i].Vendor NEQ "Sabrent") DriveData[i].Vendor="Sabrent";
if (ListFirst(DriveData[i].Model," ") EQ "Sabrent" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="Sabrent";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,5) EQ "SSSTC" AND DriveData[i].Vendor NEQ "SSSTC") DriveData[i].Vendor="SSSTC";
if (ListFirst(DriveData[i].Model," ") EQ "SSSTC" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="SSSTC";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,7) EQ "T-FORCE" AND DriveData[i].Vendor NEQ "T-FORCE") DriveData[i].Vendor="T-FORCE";
if (ListFirst(DriveData[i].Model," ") EQ "T-FORCE" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="T-FORCE";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}
if (Left(DriveData[i].Vendor,8) EQ "DAPUSTOR" AND DriveData[i].Vendor NEQ "DAPUSTOR") DriveData[i].Vendor="DAPUSTOR";
if (ListFirst(DriveData[i].Model," ") EQ "DAPUSTOR" AND ListLen(DriveData[i].Model," " GT 1)) {DriveData[i].Vendor="DAPUSTOR";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,1," ");}

if (Left(DriveData[i].Vendor,17) EQ "Seagate Barracuda") DriveData[i].Vendor="Seagate";
if (Left(DriveData[i].Vendor,16) EQ "Seagate FireCuda") DriveData[i].Vendor="Seagate";
if (Left(DriveData[i].Vendor,9) EQ "SK hynix ") DriveData[i].Vendor="SK hynix";

if (ListLast(DriveData[i].Model," ") EQ "KIOXIA") {DriveData[i].Vendor="KIOXIA";DriveData[i].Model=ListDeleteAt(DriveData[i].Model,ListLen(DriveData[i].Model," ")," ");}

if (Left(DriveData[i].Vendor,4) EQ "JAJP") DriveData[i].Vendor="Lares";

if (ListFindNoCase("PCIe SSD,Generic,QEMU",DriveData[i].Vendor)) Skip=1;
if (ListFindNoCase("LOGICAL VOLUME",DriveData[i].Model)) Skip=1;
</cfscript>




			<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=DriveData[i].Vendor>
			<CFSET HW[Key].Ports[PortNo].Attrib.Model=DriveData[i].Model>


			<CFSET Vendor=HW[Key].Ports[PortNo].Attrib.Vendor>
			<CFSWITCH expression="#Vendor#">
				<CFCASE value="Apple">
					<!--- Apple drives are rebranded --->
					<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="Unknown">
					<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ") EQ "HDD">
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1," ")>
					</CFIF>
				</CFCASE>
				<CFCASE value="Western Digital">
					<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Serial,"-") EQ "WD">
						<CFSET HW[Key].Ports[PortNo].Attrib.Serial=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Serial,1,"-")>
					</CFIF>
					<CFIF ListLen(HW[Key].Ports[PortNo].Attrib.Model,"-") GT 1>
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"-")>
					</CFIF>
				</CFCASE>
				<CFCASE value="Seagate">
					<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"-")>
				</CFCASE>
				<CFCASE value="Maxtor">
					<CFSET Model=ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"-")>
					<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(Model,1," ")>
				</CFCASE>
				<CFCASE value="SanDisk">
				</CFCASE>
				<CFCASE value="Samsung">
					<CFIF ListFindNoCase("GB,TB",Right(HW[Key].Ports[PortNo].Attrib.Model,2))>
						<CFSET tmp=ListLast(HW[Key].Ports[PortNo].Attrib.Model," ")>
						<CFSET tmp=Left(tmp,Len(tmp)-2)>
						<CFIF Val(tmp) EQ tmp>
							<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,ListLen(HW[Key].Ports[PortNo].Attrib.Model," ")," ")>
						</CFIF>
					</CFIF>
					<CFIF ListLast(HW[Key].Ports[PortNo].Attrib.Model," ") EQ "Series">
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,ListLen(HW[Key].Ports[PortNo].Attrib.Model," ")," ")>
					</CFIF>
				</CFCASE>
				<CFCASE value="ATA">
					<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Product,"-") EQ "OCZ">
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1,"-")>
						<CFSET HW[Key].Ports[PortNo].Attrib.Serial=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Serial,1,"-")>
						<CFSET HW[Key].Ports[PortNo].Attrib.Product=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Product,1,"-")>
						<CFSET HW[Key].Ports[PortNo].Attrib.Vendor="OCZ">
					<CFELSE>
						<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=ListFirst(HW[Key].Ports[PortNo].Attrib.Model," ")>
					</CFIF>
				</CFCASE>
				<CFCASE value="Hitachi">
				</CFCASE>
				<CFCASE value="ADATA">
				</CFCASE>
				<CFCASE value="HGST">
				</CFCASE>
				<CFCASE value="TOSHIBA">
				</CFCASE>
				<CFCASE value="Crucial">
					<CFIF ListLen(HW[Key].Ports[PortNo].Attrib.Model,"_") EQ 1 AND Left(HW[Key].Ports[PortNo].Attrib.Model,7) EQ "CRUCIAL" AND Len(HW[Key].Ports[PortNo].Attrib.Model) GT 7>
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=Mid(HW[Key].Ports[PortNo].Attrib.Model,8,99)>
					</CFIF>
				</CFCASE>
				<CFCASE value="CORSAIR">
					<CFIF ListFirst(HW[Key].Ports[PortNo].Attrib.Model,"-") EQ "CSSD">
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,1,"-")>
					</CFIF>
				</CFCASE>
				<CFCASE value="OCZ">
				</CFCASE>
				<CFCASE value="Mushkin">
				</CFCASE>
				<CFCASE value="Plextor">
				</CFCASE>
				<CFCASE value="PNY">
					<CFIF ListFindNoCase(HW[Key].Ports[PortNo].Attrib.Model,"SSD"," ")>
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,ListFindNoCase(HW[Key].Ports[PortNo].Attrib.Model,"SSD"," ")," ")>
					</CFIF>
					<!--- Don't remove capacity from PNY model, it's good. Only way to tell the difference
					<CFIF Right(ListLast(HW[Key].Ports[PortNo].Attrib.Model," "),2) EQ "GB" OR Right(ListLast(HW[Key].Ports[PortNo].Attrib.Model," "),2) EQ "TB">
						<CFSET HW[Key].Ports[PortNo].Attrib.Model=ListDeleteAt(HW[Key].Ports[PortNo].Attrib.Model,ListLen(HW[Key].Ports[PortNo].Attrib.Model," ")," ")>
					</CFIF>
					--->
				</CFCASE>
				<CFCASE value="SanDisk">
				</CFCASE>
				<CFCASE value="KINGSTON">
				</CFCASE>
			</CFSWITCH>
			<CFSET HW[Key].Ports[PortNo].DriveHash=LCase(Hash(HW[Key].Config.PCISlot & HW[Key].Ports[PortNo].Attrib.Product & HW[Key].Ports[PortNo].Attrib.Serial,"SHA"))>
			<!--- Future support for only testing one drive of exact same make & model & controller --->
			<CFSET HW[Key].Ports[PortNo].ModelHash=LCase(Hash(Key & HW[Key].Ports[PortNo].Attrib.Product & HW[Key].Ports[PortNo].Attrib.Version,"SHA"))>
			<CFSET HW[Key].Ports[PortNo].ModelHash=LCase(Hash(Key & HW[Key].Ports[PortNo].Attrib.Vendor & HW[Key].Ports[PortNo].Attrib.Model & HW[Key].Ports[PortNo].Attrib.Rev))>
			<!--- <cfdump var=#HW[Key].Ports[PortNo]#> --->
			<!---<CFSET HW[Key].Ports[PortNo].Attrib.Size.Bytes=HW[Key].Ports[PortNo].Attrib.configuration.BlockCount * HW[Key].Ports[PortNo].Attrib.configuration.LogicalSectorSize>--->
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Admin drive creation --->
<CFIF IsDefined("HWCreate") EQ "NO">
	<CFSET HWCreate="">
</CFIF>
<CFIF IsStruct(HWCreate)>
	<CFSET HW["Create"]=Duplicate(HWCreate)>
</CFIF>

<!--- Rebuild quick reference --->
<CFINCLUDE TEMPLATE="BuildQuickRef.cfm">
<CFSET json=SerializeJSON(Ref)>
<CFFILE action="write" file="#PersistDir#/storageref.json" output="#json#" addnewline="NO" mode="666">


<!--- <CFSET x=Ref.DriveID.SDG.Key>
<CFSET Y=Ref.DriveID.SDG.PortNo>
<CFSET HW[X].Ports[Y].Attrib.Vendor=HW[X].Ports[Y].Attrib.Model>
<CFINCLUDE TEMPLATE="BuildQuickRef.cfm"> --->



<!--- Check to see if the drives have previously been optimized
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFSET F=PersistDir & "/optimize/" & HW[Key].Ports[PortNo].DriveHash & "/optimal_block_size.txt">
			<CFIF FileExists("#F#")>
				<CFFILE action="read" file="#F#" variable="tmp">
				<CFSET HW[Key].Ports[PortNo].OptimalBlocksize=tmp>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP> --->

<!--- Read in UNRAID's drive info & map out --->
<CFIF FileExists("/var/local/emhttp/disks.ini")>
	<CFFILE action="read" file="/var/local/emhttp/disks.ini" variable="DriveInfo">
	<CFLOOP index="CurrLine" list="#DriveInfo#" delimiters="#Chr(10)#">
		<CFIF Left(CurrLine,1) EQ "[">
			<CFSET UNRAIDSlot=Mid(CurrLine,3,Len(CurrLine)-4)>
			<CFSET UNRAIDSlotSrc=Trim(UNRAIDSlot)>
			<CFIF Left(UNRAIDSlot,3) EQ "par">
				<CFSET UNRAIDSlot=Replace(UNRAIDSlot,"parity","Parity ")>
			</CFIF>
			<CFIF Left(UNRAIDSlot,3) EQ "dis">
				<CFSET UNRAIDSlot=Replace(UNRAIDSlot,"disk","Disk ")>
			</CFIF>
			<CFIF Left(UNRAIDSlot,3) EQ "cac">
				<CFSET UNRAIDSlot=Replace(UNRAIDSlot,"cache","Cache ")>
			</CFIF>
		</CFIF>
		<CFIF ListFirst(CurrLine,"=") EQ "device">
			<CFSET DiskID=Replace(ListLast(CurrLine,"="),Chr(34),"","ALL")>
			<CFIF StructKeyExists(Ref.DriveID,DiskID)>
				<CFSET HW[Ref.DriveID[DiskID].Key].Ports[Ref.DriveID[DiskID].PortNo].UNRAIDSlotSrc=UNRAIDSlotSrc>
				<CFSET HW[Ref.DriveID[DiskID].Key].Ports[Ref.DriveID[DiskID].PortNo].UNRAIDSlot=Trim(UNRAIDSlot)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFIF>

<!--- Get mount points and size/space --->
<CFFILE action="write" file="#PersistDir#/#exe()#_df_exec.txt" output="/bin/df -B 1KB" addnewline="NO" mode="666">
<cfexecute name="/bin/df" arguments="-B 1KB" variable="DF"  timeout="90" />
<CFFILE action="write" file="#PersistDir#/#exe()#_df.txt" output="#DF#" addnewline="NO" mode="666">
<CFSET Mounted=StructNew()>
<CFLOOP index="CurrLine" list="#DF#" delimiters="#Chr(10)#">
	<CFSET Line=StripCRLF(CurrLine)>
	<CFLOOP condition="Find('  ',Line)">
		<CFSET Line=Replace(Line,"  "," ","ALL")>
	</CFLOOP>
	<CFSET Line=ListDeleteAt(Line,1," ")>
	<CFSET Line=ListDeleteAt(Line,1," ")>
	<CFSET UsedSpace=Val(ListFirst(Line," ")) * 1000>
	<CFSET Line=ListDeleteAt(Line,1," ")>
	<CFSET AvailSpace=Val(ListFirst(Line," ")) * 1000>
	<CFSET Line=ListDeleteAt(Line,1," ")>
	<CFSET Line=ListDeleteAt(Line,1," ")>
	<CFSET MountPoint=Line>
	<CFSET Mounted[MountPoint].UsedSpace=UsedSpace>
	<CFSET Mounted[MountPoint].AvailSpace=AvailSpace>
</CFLOOP>

<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<!--- Check for "0byte" solid states due to bad "nvme show-regs" above --->
			<CFIF HW[Key].Ports[PortNo].Attrib.Size.DispSize EQ "0bytes">
				<CFSET tmp=KBytes(HW[Key].Ports[PortNo].Attrib.Size.Bytes)>
				<CFSET HW[Key].Ports[PortNo].Attrib.Size.DispSize=Int(ListFirst(tmp," ")) & ListLast(tmp," ")>
				<CFSET HW[Key].Ports[PortNo].Config.SaveDir=GetSaveDir(Key,PortNo)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Output controller & drive info --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFOUTPUT>#TS()# <span class="Bold">Found controller #EncodeForHTML(HW[Key].Config.Device)#</span><br></CFOUTPUT>
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<!--- Fetch partition information --->
			<CFFILE action="write" file="#PersistDir#/#exe()#_parted_#DriveID#_exec.txt" output="/sbin/parted -m /dev/#DriveID# unit B print free" addnewline="NO" mode="666">
			<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
			<CFTRY>
				<cfexecute name="/sbin/parted" arguments="-m /dev/#DriveID# unit B print free" variable="PartInfo"  timeout="10" />
				<CFFILE action="write" file="#PersistDir#/#exe()#_parted_#DriveID#.txt" output="#PartInfo#" addnewline="NO" mode="666">
			<CFCATCH Type="Any">
				<CFFILE action="write" file="#PersistDir#/#exe()#_parted_#DriveID#_Error.txt" output="#CFCATCH.Detail#" addnewline="NO" mode="666">
				<CFSET PartInfo="">
			</CFCATCH>
			</CFTRY>
			<CFSET TotalPartitions=0>
			<CFSET Part=StructNew()>
			<CFIF Trim(StripCRLF(PartInfo)) NEQ "" AND ListLen(PartInfo,Chr(10)) GTE 2>
				<CFSET Part.PartitionTable=ListGetAt(ListGetAt(PartInfo,2,Chr(10)),6,":",true)>
				<CFSET Part.Partitions=ArrayNew(1)>
				<CFFILE action="write" file="#PersistDir#/#exe()#_blkid_-o_export_dev_#DriveID#_exec.txt" output="/sbin/blkid -o export /dev/#DriveID#" mode="666" addnewline="no">
				<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
				<CFTRY>
					<cfexecute name="/sbin/blkid" arguments="-o export /dev/#DriveID#" variable="PartInfo2"  timeout="90" />
					<CFFILE action="write" file="#PersistDir#/#exe()#_blkid_-o_export_dev_#DriveID#.txt" output="#PartInfo2#" mode="666" addnewline="no">
				<CFCATCH Type="Any">
					<CFFILE action="write" file="#PersistDir#/#exe()#_blkid_-o_export_dev_#DriveID#_Error.txt" output="#CFCATCH.Detail#" mode="666" addnewline="no">
					<CFSET PartInfo2="">
				</CFCATCH>
				</CFTRY>
				<CFIF StripCRLF(PartInfo2) NEQ "">
					<CFLOOP index="CurrLine" list="#PartInfo2#" delimiters="#Chr(10)#">
						<CFSET PartID=ListFirst(CurrLine,"=")>
						<CFSET PartVal=ListDeleteAt(CurrLine,1,"=")>
						<CFIF ListFindNoCase("DevName,PTType",PartID) EQ 0>
							<CFSET Part[PartID]=PartVal>
						</CFIF>
					</CFLOOP>
				</CFIF>
				<!--- Strip out empty lines with spaces from bad partition reads --->
				<CFSET PartInfo2="">
				<CFLOOP index="i" from="1" to="#ListLen(PartInfo,Chr(10))#">
					<CFSET CurrLine=ListGetAt(PartInfo,i,Chr(10))>
					<CFIF Trim(CurrLine) NEQ "">
						<CFSET PartInfo2=ListAppend(PartInfo2,CurrLine,Chr(10))>
					</CFIF>
				</CFLOOP>
				<CFSET PartInfo=PartInfo2>
				<!--- Extract partition information --->
				<CFLOOP index="i" from="3" to="#ListLen(PartInfo,Chr(10))#">
					<CFSET CurrLine=ListGetAt(PartInfo,i,Chr(10))>
					<CFSET CurrLine=Left(CurrLine,Len(CurrLine)-1)>
					<CFSET NR=i-2>
					<CFSET Part.Partitions[NR].PartNo=ListGetAt(CurrLine,1,":",true)>
					<CFSET Part.Partitions[NR].Start=Val(ListGetAt(CurrLine,2,":",true))>
					<CFSET Part.Partitions[NR].End=Val(ListGetAt(CurrLine,3,":",true))>
					<CFSET Part.Partitions[NR].Size=Val(ListGetAt(CurrLine,4,":",true))>
					<CFSET Part.Partitions[NR].FileSystem=ListGetAt(CurrLine,5,":",true)>
					<CFIF ListLen(CurrLine,":") GT 5>
						<CFSET Part.Partitions[NR].Name=ListGetAt(CurrLine,6,":",true)>
						<CFSET Part.Partitions[NR].Flags=ListGetAt(CurrLine,7,":",true)>
					<CFELSE>
						<CFSET Part.Partitions[NR].Name="">
						<CFSET Part.Partitions[NR].Flags="">
					</CFIF>
					<CFIF FindNoCase("linux",Part.Partitions[NR].FileSystem) EQ "linux" AND FindNoCase("linux",Part.Partitions[NR].FileSystem) EQ "swap">
						<CFSET Part.Partitions[NR].FileSystem="linuxswap">
					</CFIF>
					<CFIF Part.Partitions[NR].FileSystem EQ "dos">
						<CFSET Part.Partitions[NR].FileSystem="exfat">
					</CFIF>
					<CFIF Part.Partitions[NR].FileSystem EQ "free">
						<CFSET Part.Partitions[NR].PartNo="">
						<CFSET Part.Partitions[NR].UUID="">
						<CFSET Part.Partitions[NR].PARTUUID="">
						<CFSET Part.Partitions[NR].MountPoint="">
					<CFELSE>
						<CFSET TotalPartitions=TotalPartitions+1>
						<!--- Fetch UUID's for the partition --->
						<CFSET P="">
						<CFIF Left(DriveID,4) EQ "nvme">
							<CFSET P="p">
						</CFIF>
						<CFSET Args="-o export /dev/#DriveID#" & P & Part.Partitions[NR].PartNo>
						<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-o_export_dev_#DriveID##P##Part.Partitions[NR].PartNo#_exec.txt" output="/sbin/blkid #Args#" addnewline="NO" mode="666">
						<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
						<CFTRY>
							<cfexecute name="/sbin/blkid" arguments="#Args#" variable="PartInfo2"  timeout="90" />
							<CFIF StripCRLF(PartInfo2) EQ "">
								<!--- No output, try without partition id --->
								<CFSET Args="-o export /dev/#DriveID#">
								<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-o_export_dev_#DriveID#_exec.txt" output="/sbin/blkid #Args#" addnewline="NO" mode="666">
								<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
								<cfexecute name="/sbin/blkid" arguments="#Args#" variable="PartInfo2"  timeout="90" />
							</CFIF>
							<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-o_export_dev_#DriveID##P##Part.Partitions[NR].PartNo#.txt" output="#PartInfo2#" addnewline="NO" mode="666">
							<CFLOOP index="CurrLine" list="#PartInfo2#" delimiters="#Chr(10)#">
								<CFSET PartID=ListFirst(CurrLine,"=")>
								<CFSET PartVal=ListDeleteAt(CurrLine,1,"=")>
								<CFIF ListFindNoCase("DevName,Type",PartID) EQ 0>
									<CFSET Part.Partitions[NR][PartID]=PartVal>
								</CFIF>
							</CFLOOP>
						<CFCATCH Type="Any">
							<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-o_export_dev_#DriveID##P##Part.Partitions[NR].PartNo#_error.txt" output="#CFCATCH.Message# #CFCatch.Detail#" addnewline="NO" mode="666">
						</CFCATCH>
						</CFTRY>
						<CFIF StructKeyExists(Part.Partitions[NR],"UUID") EQ "NO">
							<CFSET Part.Partitions[NR].UUID="">
						</CFIF>
						<CFIF StructKeyExists(Part.Partitions[NR],"PARTUUID") EQ "NO">
							<CFSET Part.Partitions[NR].PARTUUID="">
						</CFIF>
						<!--- Fetch mount point --->
						<CFSET Args="-n -o mountpoint /dev/#DriveID##p#" & Part.Partitions[NR].PartNo>
						<CFTRY>
							<CFSET Retry=0>
							<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID##P##Part.Partitions[NR].PartNo#_exec.txt" output="/bin/lsblk #Args#" addnewline="NO" mode="666">
							<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
							<cfexecute name="/bin/lsblk" arguments="#Args#" variable="PartInfo2"  timeout="90" />
							<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID##P##Part.Partitions[NR].PartNo#.txt" output="#PartInfo2#" addnewline="NO" mode="666">
							<CFSET Part.Partitions[NR].MountPoint=StripCRLF(PartInfo2)>
						<CFCATCH Type="Any">
							<CFSET Retry=1>
							<CFSET Part.Partitions[NR].MountPoint="">
							<CFSET Part.Partitions[NR].MountPointError=CFCATCH.Message & " - " & CFCATCH.Detail>
							<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID##P##Part.Partitions[NR].PartNo#_error.txt" output="#CFCATCH.Message# #CFCatch.Detail#" addnewline="NO" mode="666">
						</CFCATCH>
						</CFTRY>

						<CFIF Retry EQ 1>
							<CFSET Args="-n -o mountpoint /dev/#DriveID#">
							<CFTRY>
								<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID#_exec.txt" output="/bin/lsblk #Args#" addnewline="NO" mode="666">
								<CFIF URL.Debug NEQ "FOOBAR"><cfmodule template="cf_flushfs.cfm"></CFIF>
								<cfexecute name="/bin/lsblk" arguments="#Args#" variable="PartInfo2"  timeout="90" />
								<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID#.txt" output="#PartInfo2#" addnewline="NO" mode="666">
								<CFSET Part.Partitions[NR].MountPoint=StripCRLF(PartInfo2)>
							<CFCATCH Type="Any">
								<CFSET Part.Partitions[NR].MountPoint="">
								<CFSET Part.Partitions[NR].MountPointError=CFCATCH.Message & " - " & CFCATCH.Detail>
								<CFFILE action="write" file="#PersistDir#/#exe()#_lsblk_-n_-o_mountpount_dev_#DriveID#_error.txt" output="#CFCATCH.Message# #CFCatch.Detail#" addnewline="NO" mode="666">
							</CFCATCH>
							</CFTRY>
						</CFIF>

						<CFIF Part.Partitions[NR].MountPoint NEQ "">
							<CFIF StructKeyExists(Mounted,Part.Partitions[NR].MountPoint)>
								<CFSET Part.Partitions[NR].AvailSpace=Mounted[Part.Partitions[NR].MountPoint].AvailSpace>
								<CFSET Part.Partitions[NR].UsedSpace=Mounted[Part.Partitions[NR].MountPoint].UsedSpace>
							</CFIF>
						</CFIF>
					</CFIF>
				</CFLOOP>
				<CFIF ArrayLen(Part.Partitions) EQ 2>
					<CFIF Part.Partitions[1].FileSystem EQ "free"
					AND ListFindNoCase("free,unknown",Part.Partitions[2].FileSystem) EQ 0
					AND HW[Key].Ports[PortNo].UNRAIDSlotSrc NEQ "">
						<CFSET Part.Partitions[2].MountPoint="/mnt/UNRAID/" & HW[Key].Ports[PortNo].UNRAIDSlotSrc>
					</CFIF>
				</CFIF>
			</CFIF>
			<CFSET HW[Key].Ports[PortNo].Partitions=Duplicate(Part)>
			<CFOUTPUT>
			#TS()# Found drive #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Vendor)#
			<CFIF HW[Key].Ports[PortNo].Attrib.Vendor NEQ HW[Key].Ports[PortNo].Attrib.Model>
				#EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Model)#
			</CFIF>
			<CFIF HW[Key].Ports[PortNo].Attrib.Rev NEQ "">
				Rev: #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Rev)#
			</CFIF>
			Serial: #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Serial)# (#DriveID#), #TotalPartitions# partition<CFIF TotalPartitions NEQ 1>s</CFIF><br>
			</CFOUTPUT>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFFLUSH>


<!--- Set & Load drive image settings --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"CDROM") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].CDROM=0>
		</CFIF>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET HW[Key].Ports[PortNo].Config=StructNew()>
				<CFSET DriveDir=GetSaveDir(Key,PortNo)>
				<CFIF DirectoryExists("#PersistDir#/driveinfo/#DriveDir#") EQ "NO">
					<CFDIRECTORY action="Create" directory="#PersistDir#/driveinfo/#DriveDir#" createpath="true" mode="666">
				</CFIF>
				<CFIF FileExists("#PersistDir#/driveinfo/#DriveDir#/config.json")>
					<CFFILE action="read" file="#PersistDir#/driveinfo/#DriveDir#/config.json" variable="JSON">
					<CFSET HW[Key].Ports[PortNo].Config=DeserializeJSON(JSON)>
					<CFSET HW[Key].Ports[PortNo].Config.FetchInfo=0>
					<CFSET HW[Key].Ports[PortNo].Config.DefaultImage=0>
					<CFSET HW[Key].Ports[PortNo].Config.DriveEdited=0>
					<CFIF FileExists("#PersistDir#/driveinfo/#DriveDir#/image.png")>
						<CFSET Destn="#RootDir#/images/inuse/#CurrInstance#/#DriveDir#.png">
						<CFFILE action="copy" source="#PersistDir#/driveinfo/#DriveDir#/image.png" destination="#Destn#">
					</CFIF>
				<CFELSE>
					<CFSET HW[Key].Ports[PortNo].Config.FetchInfo=1>
					<CFSET HW[Key].Ports[PortNo].Config.ImageWidth=128>
					<CFSET HW[Key].Ports[PortNo].Config.ImageHeight=172>
					<CFSET HW[Key].Ports[PortNo].Config.Interface="">
					<CFSET HW[Key].Ports[PortNo].Config.RPM="">
					<CFSET HW[Key].Ports[PortNo].Config.Cache="">
					<CFSET HW[Key].Ports[PortNo].Config.TextOverlay=1>
					<CFSET HW[Key].Ports[PortNo].Config.TextX=64>
					<CFSET HW[Key].Ports[PortNo].Config.TextY=86>
					<CFSET HW[Key].Ports[PortNo].Config.CenterX=1>
					<CFSET HW[Key].Ports[PortNo].Config.CenterY=1>
					<CFSET HW[Key].Ports[PortNo].Config.FontSize=20>
					<CFSET HW[Key].Ports[PortNo].Config.TextRotation=0>
					<CFSET HW[Key].Ports[PortNo].Config.TextFont="Arial">
					<CFSET HW[Key].Ports[PortNo].Config.TextBold=0>
					<CFSET HW[Key].Ports[PortNo].Config.TextItalics=0>
					<CFSET HW[Key].Ports[PortNo].Config.FontColor="000000">
					<CFSET HW[Key].Ports[PortNo].Config.DefaultImage=1>
					<CFSET HW[Key].Ports[PortNo].Config.DriveEdited=0>
					<CFSET HW[Key].Ports[PortNo].Config.Random=GetTickCount() & RandRange(0,9999)>
					<CFSET HW[Key].Ports[PortNo].Config.TextCSS="color:black;font-size:30px;vertical-align:middle;text-align:center;line-height:175px;">
					<CFSET JSON=SerializeJSON(HW[Key].Ports[PortNo].Config)>
					<CFFILE action="write" file="#PersistDir#/driveinfo/#DriveDir#/config.json" output="#JSON#" addnewline="false" mode="666">
					<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#PersistDir#/driveinfo/#DriveDir#/image.png">
				</CFIF>
				<CFSET HW[Key].Ports[PortNo].Config.SaveDir=DriveDir>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Set image & text for USB drives --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 1>
					<CFLOOP index="CurrKey" list="#StructKeyList(BlankUSBConfig)#">
						<CFSET HW[Key].Ports[PortNo].Config[CurrKey]=BlankUSBConfig[CurrKey]>
					</CFLOOP>
					<CFSWITCH expression="#Len(HW[Key].Ports[PortNo].Attrib.Size.DispSize)#">
						<CFCASE VALUE="3"><CFSET HW[Key].Ports[PortNo].Config.TextCSS="width:128px;font:18px Arial;color:000000;text-indent:46px;padding-top:84px;height:106px;cursor:default;"></CFCASE>
						<CFCASE VALUE="4"><CFSET HW[Key].Ports[PortNo].Config.TextCSS="width:128px;font:18px Arial;color:000000;text-indent:41px;padding-top:84px;height:106px;cursor:default;"></CFCASE>
						<CFCASE VALUE="5"><CFSET HW[Key].Ports[PortNo].Config.TextCSS="width:128px;font:18px Arial;color:000000;text-indent:36px;padding-top:84px;height:106px;cursor:default;"></CFCASE>
						<CFCASE VALUE="6"><CFSET HW[Key].Ports[PortNo].Config.TextCSS="width:128px;font:18px Arial;color:000000;text-indent:30px;padding-top:84px;height:106px;cursor:default;"></CFCASE>
					</CFSWITCH>
					<CFSET Destn="#RootDir#/images/inuse/#CurrInstance#/" & HW[Key].Ports[PortNo].Config.SaveDir & ".png">
					<CFFILE action="copy" source="#RootDir#/images/usb.png" destination="#Destn#">
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Check for missing keys (part 1) --->
<CFSET ConfigVars="OptVer2_9|0,FetchInfo|1,ImageWidth|128,ImageHeight|172,Interface|,RPM|,Cache|,TextOverlay|1,TextX|64,TextY|86,CenterX|1,CenterY|1," &
				  "FontSize|20,TextRotation|0,TextFont|Arial,TextBold|0,TextItalics|0,FontColor|ffffff,DefaultImage|1,DriveEdited|0,Random|0," &
				  "TextCSS|color:white;font-size:30px;vertical-align:middle;text-align:center;line-height:175px;,GoogleFont|">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFLOOP index="CurrCFG" list="#ConfigVars#">
					<CFSET CheckKey=ListFirst(CurrCFG,"|")>
					<CFIF ListLen(CurrCFG,"|") EQ 1>
						<CFSET CheckVal="">
					<CFELSE>
						<CFSET CheckVal=ListLast(CurrCFG,"|")>
					</CFIF>
					<CFIF StructKeyExists(HW[Key].Ports[PortNo].Config,CheckKey) EQ "false">
						<CFSET HW[Key].Ports[PortNo].Config[CheckKey]=CheckVal>
					</CFIF>
				</CFLOOP>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<!--- <cfdump var=#hw#><cfabort> --->
<!--- Dump empty slots --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID EQ "">
			<CFSET HW[Key].Ports[PortNo]=StructNew()>
			<CFSET HW[Key].Ports[PortNo].DriveID="">
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Check for bad drive data and disable submitting them if found --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET DriveDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>
				<CFIF StructKeyExists(HW[Key].Ports[PortNo],"UNRAIDSlot")>
					<CFIF HW[Key].Ports[PortNo].UNRAIDSLot EQ "flash">
						<CFFILE action="write" file="#DriveDir#/nobsubmit.txt" output="" addnewline="NO" mode="666">
					</CFIF>
				</CFIF>
				<CFIF IsUnicode(HW[Key].Ports[PortNo].Attrib.Vendor) OR IsUnicode(HW[Key].Ports[PortNo].Attrib.Model) OR IsUnicode(HW[Key].Ports[PortNo].Attrib.Rev) OR HW[Key].Ports[PortNo].CDROM EQ 1>
					<CFFILE action="write" file="#DriveDir#/nobsubmit.txt" output="" addnewline="NO" mode="666">
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<!--- Create Contoller Hash to detect if bandwidth test was for current drive configuration, restore old Optimized Drive value if existing --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFSET BandwidthHash="">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
					<CFSET BandwidthHash=ListAppend(BandwidthHash,HW[Key].Ports[PortNo].Config.SaveDir)>
				<CFELSE>
					<CFSET BandwidthHash=ListAppend(BandwidthHash,"N/A")>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<CFSET HW[Key]["BandwidthHash"]=LCase(Hash(BandwidthHash))>
	<CFIF IsStruct(OldHW)>
		<CFIF StructKeyExists(OldHW,Key)>
			<CFIF StructKeyExists(OldHW[Key],"BandwidthHash")>
				<CFIF OldHW[Key].BandwidthHash EQ LCase(Hash(BandwidthHash))>
					<CFSET HW[Key].BandwidthHash=OldHW[Key].BandwidthHash>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>
<CFIF IsStruct(OldHW)>
	<!--- Restore other variables --->
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFTRY>
				<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
					<CFIF StructKeyExists(OldHW,Key)>
						<CFIF PortNo LTE ArrayLen(OldHW[Key].Ports)>
							<CFIF HW[Key].Ports[PortNo].DevicePath EQ OldHW[Key].Ports[PortNo].DevicePath>
								<CFIF StructKeyExists(OldHW[Key].Ports[PortNo].Config,"OptVer2_9")>
									<CFSET HW[Key].Ports[PortNo].Config.OptVer2_9=OldHW[Key].Ports[PortNo].Config.OptVer2_9>
								</CFIF>
							</CFIF>
						</CFIF>
					</CFIF>
				</CFIF>
			<CFCATCH Type="Any">
				<!--- Eat any errros --->
			</CFCATCH>
			</CFTRY>
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device">
					<CFSET HW[Key].Ports[PortNo]["IsSSD"]=1>
					<!--- Restore SSD Benchmark tests --->
					<CFSET BenchmarksDir="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark">
					<CFSET MaxBenchDate=CreateDate(1970,1,1)>
					<CFSET UseBenchDir="">
					<CFDIRECTORY action="list" directory="#BenchmarksDir#" type="Dir" name="BenchDir">
					<CFLOOP index="CR" from="1" to="#BenchDir.RecordCount#">
						<CFIF FileExists("#BenchmarksDir#/#BenchDir.Name[CR]#/valid.txt") AND FileExists("#BenchmarksDir#/#BenchDir.Name[CR]#/datestamp.txt")>
							<CFFILE action="read" file="#BenchmarksDir#/#BenchDir.Name[CR]#/datestamp.txt" variable="BenchDate">
							<CFIF DateCompare(BenchDate,MaxBenchDate,"s") EQ 1>
								<CFSET MaxBenchDate=BenchDate>
								<CFSET UseBenchDir=BenchDir.Name[CR]>
							</CFIF>
						</CFIF>
					</CFLOOP>
					<CFIF UseBenchDir NEQ "">
						<!---<CFOUTPUT>[#HW[Key].Ports[PortNo].DriveID# last benchmark restored]<br></cfoutput>--->
						<CFIF FileExists("#BenchmarksDir#/#UseBenchDir#/SSDReadSpeed.txt")>
							<CFSET SSDRead=ReadFile("#BenchmarksDir#/#UseBenchDir#/SSDReadSpeed.txt")>
							<CFSET SSDWrite=ReadFile("#BenchmarksDir#/#UseBenchDir#/SSDWriteSpeed.txt")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark=StructNew()>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadAvg=ListFirst(SSDRead,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadMin=ListGetAt(SSDRead,2,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadMax=ListLast(SSDRead,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteAvg=ListFirst(SSDWrite,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteMin=ListGetAt(SSDWrite,2,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteMax=ListGetAt(SSDWrite,3,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteLow=ListLast(SSDWrite,"|")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.Bouncy=ReadFile("#BenchmarksDir#/#UseBenchDir#/Bouncy.txt","0")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetected=ReadFile("#BenchmarksDir#/#UseBenchDir#/CacheDetected.txt","0")>
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetectedAt=ReadFile("#BenchmarksDir#/#UseBenchDir#/CacheDetectedAt.txt","0")>
						</CFIF>
					<CFELSE>
						<!---<CFOUTPUT>[#HW[Key].Ports[PortNo].DriveID# last benchmark not found]<br></cfoutput>--->
					</CFIF>
				<CFELSE>
					<CFSET HW[Key].Ports[PortNo]["IsSSD"]=0>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFIF>

<CFSET NeedImage="">
<CFSET NeedPlatter="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET tmpdir=HW[Key].Ports[PortNo].Config.SaveDir>
				<CFIF HW[Key].Ports[PortNo].Config.FetchInfo EQ 1 OR HW[Key].Ports[PortNo].Config.DefaultImage EQ 1 OR FileExists("#PersistDir#/driveinfo/#tmpdir#/image.png") EQ "NO">
					<CFSET NeedImage=ListAppend(NeedImage,"#Key#|#PortNo#","~")>
				</CFIF>
				<CFIF HW[Key].Ports[PortNo].Attrib.PlatterCnt EQ 0>
					<CFSET NeedPlatter=ListAppend(NeedPlatter,"#Key#|#PortNo#","~")>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<CFIF URL.Debug NEQ "FOOBAR">
	<!--- Don't fetch extra stuff if we're building a debug file --->
	<CFSET NeedImage="">
	<CFSET NeedPlatter="">
</CFIF>

<CFINCLUDE TEMPLATE="BuildQuickRef.cfm">
<CFSET json=SerializeJSON(Ref)>
<CFFILE action="write" file="#PersistDir#/storageref.json" output="#json#" addnewline="NO" mode="666">
<CFIF NeedImage NEQ "">
	<CFINCLUDE TEMPLATE="GetInitialDriveImage.cfm">
</CFIF>

<CFIF NeedPlatter NEQ "">
	<CFINCLUDE TEMPLATE="GetPlatterInfo.cfm">
</CFIF>

<CFINCLUDE TEMPLATE="ProcessBenchmarks.cfm">
<CFFILE action="write" file="/tmp/DiskSpeedTmp/firstrun.txt" output="" addnewline="NO" mode="666">

<CFIF ListLen(Config.var.RegTo,".") EQ 4>
	<CFSET Config.var.RegTo=MiscRef.MBSerial>
</CFIF>
<CFSET UserIDSHA=Hash(Hash(Config.var.RegTo,"SHA") & Hash(Config.var.RegGUID,"SHA"),"SHA")>

<!--- Check HDDB for drives --->
<CFSET CheckHDDB=ArrayNew(1)>
<CFSET CheckHDDBList="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
				<CFSET CurrDrive=Drive.Attrib.Vendor & "|" & Drive.Attrib.Model & "|" & Drive.Attrib.Rev & "~">
				<CFIF ListFindNoCase(CheckHDDBList,CurrDrive) EQ 0>
					<CFSET CheckHDDBList=ListAppend(CheckHDDBList,CurrDrive)>
					<CFSET i=ArrayLen(CheckHDDB) + 1>
					<CFSET CheckHDDB[i]=StructNew()>
					<CFSET CheckHDDB[i].V=Drive.Attrib.Vendor>
					<CFSET CheckHDDB[i].M=Drive.Attrib.Model>
					<CFSET CheckHDDB[i].R=Drive.Attrib.Rev>
					<CFSET CheckHDDB[i].U=UserIDSHA>
					<CFSET CheckHDDB[i].H=Hash36("#Drive.Attrib.Vendor#|#Drive.Attrib.Model#|#Drive.Attrib.Serial#")>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFSET CheckHDDBJSON=SerializeJSON(CheckHDDB)>
<CFSET H=LCase(Hash(CheckHDDBJSON & URLEncodedFormat(CheckHDDBJSON)))>
<CFOUTPUT>#TS()# Checking Hard Drive Database for drives<br></CFOUTPUT><CFFLUSH>
<!--- <cfoutput>Drives: #URLEncodedFormat(CheckHDDBJson)#<br>h: #LCase(Hash(CheckHDDBJSON & URLEncodedFormat(CheckHDDBJSON)))#<br></cfoutput> --->
<CFTRY>
	<CFHTTP method="POST" URL="#StrangeJourney#/diskspeed/CheckHDDB.cfm" throwonerror="NO" timeout="15">
		<CFHTTPPARAM type="formfield" name="Drives" value="#CheckHDDBJSON#">
		<CFHTTPPARAM type="formfield" name="h" value="#H#">
	</CFHTTP>
	<CFSET HDDBResult=DeserializeJSON(CFHTTP.FileContent)>
	<CFLOOP index="i" from="1" to="#ArrayLen(CheckHDDB)#">
		<CFSET SetDrives=Ref.Vendor[CheckHDDB[i].V][CheckHDDB[i].M]>
		<CFLOOP index="CurrKey" list="#SetDrives#">
			<CFSET Key=ListFirst(CurrKey,"|")>
			<CFSET PortNo=ListLast(CurrKey,"|")>
			<CFSET HW[Key].Ports[PortNo].HDDBFound=HDDBResult[i]>
		</CFLOOP>
	</CFLOOP>
<CFCATCH Type="Any">
	<!--- Eat any errors --->
</CFCATCH>
</CFTRY>

<!--- Post HW Scan --->
<CFSET TotalImg=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"IsSSD") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].IsSSD=0>
		</CFIF>
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<!--- Flag drives with no Center Flags as optimized for version 2.9+ --->
				<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 0 AND HW[Key].Ports[PortNo].Config.CenterX EQ 0 AND HW[Key].Ports[PortNo].Config.CenterY EQ 0>
					<CFSET HW[Key].Ports[PortNo].Config.OptVer2_9=1>
				</CFIF>
				<CFTRY>
					<!--- Assign mounted partition space --->
					<CFLOOP index="PartID" from="1" to="#ArrayLen(HW[Key].Ports[PortNo].Partitions.Partitions)#">
						<CFSET MP=HW[Key].Ports[PortNo].Partitions.Partitions[PartID].MountPoint>
						<CFIF MP NEQ "">
							<CFIF StructKeyExists(Mounted,MP)>
								<CFSET HW[Key].Ports[PortNo].Partitions.Partitions[PartID].AvailSpace=Mounted[MP].AvailSpace>
								<CFSET HW[Key].Ports[PortNo].Partitions.Partitions[PartID].UsedSpace=Mounted[MP].UsedSpace>
							</CFIF>
						</CFIF>
					</CFLOOP>
				<CFCATCH Type="Any">
				</CFCATCH>
				</CFTRY>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Check for missing keys (part 2) and misc cleanup --->
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF StructKeyExists(HW[Key].Config,"LnkSta") EQ "NO">
		<CFSET HW[Key].Config.LnkSta=StructNew("ordered")>
	</CFIF>
	<CFIF StructKeyExists(HW[Key].Config,"LnkCap") EQ "NO">
		<CFSET HW[Key].Config.LnkCap=StructNew("ordered")>
	</CFIF>
	<CFLOOP index="VarName" list="PCIEVER,LINECODEL,SPEED,LINECODEH,WIDTH,THROUGHPUT,OVERHEADMB,THROUGHPUTMB">
		<CFIF StructKeyExists(HW[Key].Config.LnkSta,VarName) EQ "NO">
			<CFSET HW[Key].Config.LnkSta[VarName]="">
		</CFIF>
		<CFIF StructKeyExists(HW[Key].Config.LnkCap,VarName) EQ "NO">
			<CFSET HW[Key].Config.LnkCap[VarName]="">
		</CFIF>
	</CFLOOP>
	<CFIF StructKeyExists(HW[Key].Config,"Product") EQ "NO">
		<CFSET HW[Key].Config.Product="Unknown Controller">
	</CFIF>
	<CFIF HW[Key].Config.Product EQ "Unknown Controller">
		<CFSET HW[Key].Config.Product=HW[Key].Config.Device>
	</CFIF>
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"Config") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].Config=StructNew()>
		</CFIF>
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"SSD_Benchmark")>
			<CFIF StructKeyExists(HW[Key].Ports[PortNo].SSD_Benchmark,"Bouncy") EQ "NO">
				<CFSET HW[Key].Ports[PortNo].SSD_Benchmark=0>
			</CFIF>
		</CFIF>
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"Partitions") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].Partitions=StructNew("ordered")>
		</CFIF>
		<CFIF StructKeyExists(HW[Key].Ports[PortNo].Partitions,"Partitions") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].Partitions.Partitions=ArrayNew(1)>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Check for duplicate partition UUID's
<CFSET DupeUUID=StructNew()>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF StructKeyExists(HW[Key].Ports[PortNo],"Partitions")>
				<CFLOOP index="i" from="1" to="#ArrayLen(HW[Key].Ports[PortNo].Partitions.Partitions)#">
					<CFIF StructKeyExists(HW[Key].Ports[PortNo].Partitions.Partitions[i],"UUID")>
						<CFSET UUID=HW[Key].Ports[PortNo].Partitions.Partitions[i].UUID>
						<CFSET MountPoint="">
						<CFIF StructKeyExists(HW[Key].Ports[PortNo].Partitions.Partitions[i],"MountPoint")>
							<CFSET MountPoint=HW[Key].Ports[PortNo].Partitions.Partitions[i].MountPoint>
						</CFIF>
						<CFIF StructKeyExists(DupeUUID,UUID) EQ "NO">
							<CFSET DupeUUID[UUID]="">
						</CFIF>
						<!---<CFIF MountPoint NEQ "">--->
							<CFSET DupeUUID[UUID]=ListAppend(DupeUUID[UUID],DriveID)>
						<!---</CFIF>--->
					</CFIF>
				</CFLOOP>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFIF StructKeyList(DupeUUID) NEQ "">
</CFIF> --->

<cflock name="CreateFile" type="exclusive" throwontimeout="false" timeout="5">
<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(HWTree)>
<CFFILE action="write" file="#PersistDir#/hwtree.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(USBTree)>
<CFFILE action="write" file="#PersistDir#/usbtree.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(MiscRef)>
<CFFILE action="write" file="#PersistDir#/miscref.json" output="#json#" addnewline="NO" mode="666">
</cflock>

<!--- Parse SMART data --->
<CFINCLUDE TEMPLATE="SubmitSMARTData.cfm">

<!--- Count total drive images to optimize --->
<CFSET TotalImg=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 0 AND HW[Key].Ports[PortNo].Config.CenterX EQ 1 AND HW[Key].Ports[PortNo].Config.CenterY EQ 1 AND HW[Key].Ports[PortNo].Config.OptVer2_9 EQ 0>
					<CFSET TotalImg=TotalImg + 1>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Generate drive CSS & process drive images --->
<CFSET CSS="">
<CFSET CSSTD="">
<CFSET CSSH="">
<CFSET CSSHN="">
<CFSET CSSHN2="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET C=HW[Key].Ports[PortNo].Config>
				<CFIF FileExists("#RootDir#/images/inuse/#CurrInstance#/#C.SaveDir#.png") EQ "NO">
					<cffile action="copy" source="#PersistDir#/driveinfo/#C.SaveDir#/image.png" destination="#RootDir#/images/inuse/#CurrInstance#/#C.SaveDir#.png">
				</CFIF>
				<CFSET OutTextCSS=C.TextCSS>
				<!--- Pad Text Indent and override width --->
				<CFSET Loc=REFindNoCase("text-indent:\d*px;",C.TextCSS,1,true)>
				<CFIF Loc.Pos[1] GT 0>
					<CFSET NewIndent=Val(ListLast(Mid(C.TextCSS,Loc.Pos[1],Loc.Len[1]),":")) + 4>
					<CFSET OutTextCSS=Replace(C.TextCSS,Mid(C.TextCSS,Loc.Pos[1],Loc.Len[1]),"") & "text-indent:#NewIndent#px;cursor:pointer;">
					<CFIF Find("rotate",OutTextCSS)>
						<CFSET OutTextCSS=Replace(OutTextCSS,"rotate(180deg);","rotate(180deg);margin-bottom:8px;")>
					<CFELSE>
						<!--- <CFSET OutTextCSS=OutTextCSS & "margin-top:8px;"> --->
					</CFIF>
					<!--- Style fix --->
					<CFIF REFindNoCase("color:[0-9a-z]",OutTextCSS)>
						<CFSET OutTextCSS=Replace(OutTextCSS,"color:","color:##")>
					</CFIF>
				</CFIF>
				<!--- <CFSET Loc=REFindNoCase("width:\d*px;",C.TextCSS,1,true)>
				<CFIF Loc.Pos[1] GT 0>
					<CFSET C.TextCSS=Replace(C.TextCSS,Mid(C.TextCSS,Loc.Pos[1],Loc.Len[1]),"") & "width:137px;">
				</CFIF> --->

				<CFSET CSS=CSS & "." & CSSName(C.SaveDir) & " {#OutTextCSS#}" & Chr(10)>
				<CFSET CSSTD=CSSTD & "." & CSSName(C.SaveDir) & "_td {background-image:url('images/inuse/#CurrInstance#/#C.SaveDir#.png?random=#C.Random#');background-position:center;background-repeat:no-repeat;width:128px;height:190px;}" & Chr(10)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFFILE action="write" file="#SaveDir#/drives.css" output="#CSS##CSSTD##CSSHN##CSSHN2#" addnewline="NO" mode="666">

<!---
<CFIF FileExists("/tmp/DiskSpeedTmp/Instances/local/drives.css") EQ "NO">
	<CFSET TotalImg=0>
</CFIF>
--->

<CFOUTPUT>
<CFIF TotalImg GT 0>
	#TS()# Optimizing images...<br>
</CFIF>
<div id="ContinueBlock" style="display:none">
#TS()# Configuration saved<br>
<br>
<form id="go" action="index.cfm" method="get">
<input type="submit" id="SubmitButton" value="Continue<!--- <CFIF NOT DiskSpeedDeveloper> (10)</CFIF> --->">
</form>
</div>

<CFIF ErrorFlag EQ 1>
<CFSET ErrorReason=ListAppend(ErrorReason,"Drive Spinup 2","|")>
	<a href="isolated/CreateDebugInfo.cfm?Back=1">Please create a Debug File</a> and email it to harddrivedb@gmail.com<br>
	<CFIF ErrorReason NEQ "">
		Please include the following information:<br>
		* #Replace(ErrorReason,"|","<br>* ","ALL")#</ul>
	</CFIF>
	</big>
<CFELSEIF URL.Debug NEQ "FOOBAR">
	<br><big><font color="red">Debug flag set.</font> <a href="isolated/CreateDebugInfo.cfm?Back=1">Create Debug File</a> and email it to harddrivedb@gmail.com<br></big>
</CFIF>

<script>
var TotalImg=#TotalImg#;
function ProcessImg()
{
	TotalImg=TotalImg - 1;
	if (TotalImg < 1) document.getElementById('ContinueBlock').style.display='block';
}
ProcessImg();
</script>
<!--- TotalImg: #TotalImg#<br> --->
</CFOUTPUT>

<CFIF TotalImg GT 0 AND URL.Debug NEQ "Export">
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 0 AND HW[Key].Ports[PortNo].CDROM EQ 0 AND HW[Key].Ports[PortNo].Config.CenterX EQ 1 AND HW[Key].Ports[PortNo].Config.CenterY EQ 1 AND HW[Key].Ports[PortNo].Config.OptVer2_9 EQ 0>
					<CFSET URLVars="Drive=" & URLEncode("#Key#|#PortNo#") & "&Edit=Y&AutoSubmit=Y&DontBackupJSON=Y">
					<CFOUTPUT><iframe src="EditDrive.cfm?#URLVars#" class="KindaHidden" width="500" height="500"></iframe></CFOUTPUT><CFFLUSH>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFIF>

<CFOUTPUT>
<script>
var endTime = performance.now()
var execTime=endTime - startTime;
if (execTime < 200) {
	document.write('<font color="red">Warning:</font> Browser contents were intercepted or cached instead of being delivered in real time. This application will still function but you will experience long ' +
				   'apparent delays with only a white screen until the application is done doing whatever it\'s doing. For example, if you benchmark one drive, you will see a white ' +
				   'screen for at least 3 minutes before the results are displayed and you won\'t have the ability to abort the benchmark.<br><br>Proxies or security applications ' +
				   'can cause this - for example, Acronis Cyber Protect products (you have to disable Protection, there is no option to disable just web interceptions).');
}
</script>
</CFOUTPUT>

<CFIF URL.Debug EQ "Export" OR DiskSpeedDeveloper EQ 1>
	<cfdump var=#HW#>
	<cfdump var=#Ref#>
	<cfdump var=#HWTree#>
	<cfdump var=#USBTree#>
	<cfdump var=#MiscRef#>
	<cfdump var=#Mounted#>
</CFIF>

<CFOUTPUT>
</body>
</html>
</CFOUTPUT>

<CFFLUSH>
<CFIF URL.Debug EQ "FOOBAR" AND NOT DiskSpeedDeveloper AND ErrorFlag EQ 0>
	<!--- Cleanup log files --->
	<CFDIRECTORY action="list" directory="#PersistDir#/debug" type="file" name="Dir">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="delete" file="#PersistDir#/debug/#Dir.Name[CR]#">
	</CFLOOP>
</CFIF>

<!--- Save docker info --->
<CFFILE action="write" file="#PersistDir#/docker.json" output="#SerializeJSON(DockerInfo)#" mode="666">

</cflock>
<CFIF ScanTimedout EQ 1>
	<CFOUTPUT>
	A system scan is already in progress. Please wait a minute and then <a href="index.cfm">click here</a> to see if it has completed yet.
	</CFOUTPUT>
	<CFABORT>
</CFIF>

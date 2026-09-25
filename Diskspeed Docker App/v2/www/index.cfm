<CFPARAM name="URL.Controller" default="">
<CFPARAM name="URL.ControllerBenchmark" default="N">
<CFPARAM name="URL.Benchmark" default="N">
<CFPARAM name="URL.BenchmarkDrive" default="N">
<CFPARAM name="URL.Drive" default="">
<CFPARAM name="URL.Status" default="">
<CFPARAM name="URL.PortNo" default="">
<CFPARAM name="URL.Opt2" default="N">
<CFPARAM name="URL.Opt3" default="N">
<CFPARAM name="URL.Finalize" default="N">
<CFPARAM name="URL.SubmitDrive" default="">
<CFPARAM name="FORM.ScanControllers" default="N">
<CFPARAM name="FORM.SubmitButton" default="">

<CFSET VendorList="Hitachi,Patriot,ADATA,Mushkin,Toshiba,Transcend,Micron,PNY,Plextor,OCZ,Kingston,Intel,Corsair,Crucial,Maxtor,Samsung,Sandisk,Seagate,Western Digital,HGST,Edge Tech">

<CFINCLUDE Template="SetKillFlag.cfm">
<CFINCLUDE Template="RemoveTempFiles.cfm">
<CFINCLUDE Template="PurgeLogs.cfm">

<CFIF DiskSpeedDeveloper>
	<CFINCLUDE TEMPLATE="ImportDebugFiles.cfm">
</CFIF>

<CFSET DispOutput=1>
<CFIF URL.Benchmark EQ "Y" & URL.Status EQ "Y">
	<CFSET DispOutput=0>
</CFIF>

<CFIF DirectoryExists("#RootDir#/images/inuse") EQ "NO">
	<CFDIRECTORY action="create" directory="#RootDir#/images/inuse" mode="666">
</CFIF>
<CFIF DirectoryExists("#RootDir#/images/inuse/#CurrInstance#") EQ "NO">
	<CFDIRECTORY action="create" directory="#RootDir#/images/inuse/#CurrInstance#" mode="666">
</CFIF>

<CFSET RescanControllers=0>
<CFIF ReadFile("#PersistDir#/BlockHash.txt") NEQ Hash36(Utils.GetBlockDevices())>
	<CFLOCATION URL="ScanControllers.cfm?SysChange=Y" AddToken="NO">
</CFIF>
<cflock type="Exclusive" scope="Session" throwontimeout="true" timeout="30">
	<CFPARAM name="Session.ScanCount" default="0">
	<CFSET Session.ScanCount=0>
</cflock>


<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json") AND FileExists("#PersistDir#/miscref.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
	<CFSET HWTree=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/usbtree.json" variable="json">
	<CFSET USBTree=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/miscref.json" variable="json">
	<CFSET MiscRef=DeserializeJSON(json)>
	<!--- Check for invalid storage.json --->
	<CFIF StructKeyExists(Session,"CheckedHWJson") EQ "NO">
		<CFSET OK=1>
		<CFTRY>
			<CFLOOP index="Key" list="#StructKeyList(HW)#">
				<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
					<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
						<CFIF StructKeyExists(HW[Key].Ports[PortNo],"Config") EQ "NO">
							<CFSET OK=0>
							<CFBREAK>
						</CFIF>
					</CFIF>
				</CFLOOP>
				<CFIF NOT OK>
					<CFBREAK>
				</CFIF>
			</CFLOOP>
		<CFCATCH Type="Any">
		</CFCATCH>
		</CFTRY>
		<CFIF NOT OK>
			<!--- Config struct not found, rescan hardware --->
			<CFLOCATION URL="ScanControllers.cfm?BadConfig=Y" AddToken="NO">
		<CFELSE>
			<CFSET Session.CheckedHWJson=1>
		</CFIF>
	</CFIF>
<CFELSE>

	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>

<CFIF FileExists("/tmp/DiskSpeedTmp/firstrun.txt") EQ "NO">
	<CFINCLUDE TEMPLATE="Upgrade.cfm">
	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>
<CFIF FileExists("/tmp/DiskSpeedTmp/benchdone.txt")>
	<CFFILE action="delete" file="/tmp/DiskSpeedTmp/benchdone.txt">
	<CFINCLUDE TEMPLATE="ProcessBenchmarks.cfm">
</CFIF>

<CFIF FORM.SubmitButton EQ "Purge Manual Drives" AND StructKeyExists(HW,"Create")>
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW['Create'].Ports)#">
		<CFSET Dir="#PersistDir#/driveinfo/" & HW["Create"].Ports[PortNo].Config.SaveDir>
		<CFDIRECTORY action="delete" directory="#Dir#" recurse="true">
		<CFSET FN="#RootDir#/images/inuse/#CurrInstance#/" & HW["Create"].Ports[PortNo].Config.SaveDir & ".png">
		<CFFILE action="delete" file="#FN#">
	</CFLOOP>
	<CFSET StructDelete(HW,"Create")>
	<!--- Rebuild quick reference --->
	<CFINCLUDE TEMPLATE="BuildQuickRef.cfm">
	<CFSET json=SerializeJSON(HW)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
	</cflock>
	<CFSET json=SerializeJSON(Ref)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#PersistDir#/storageref.json" output="#json#" addnewline="NO" mode="666">
	</cflock>
</CFIF>

<CFIF FORM.ScanControllers EQ "Y">
	<CFIF FORM.SubmitButton EQ "Purge Everything and Start Over">
		<CFIF DiskSpeedDeveloper>
			<!--- Delete just the files instead of directories and files --->
			<CFDIRECTORY action="list" directory="#RootDir#/images/inuse/#CurrInstance#" name="Dir" type="File" recurse="Yes">
			<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
				<CFFILE action="delete" file="#Dir.Directory[CR]#/#Dir.Name[CR]#">
			</CFLOOP>
			<CFDIRECTORY action="list" directory="#PersistDir#" name="Dir" type="File" recurse="Yes">
			<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
				<CFFILE action="delete" file="#Dir.Directory[CR]#/#Dir.Name[CR]#">
			</CFLOOP>
			<CFDIRECTORY action="list" directory="#SaveDir#" name="Dir" type="File" recurse="Yes">
			<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
				<CFFILE action="delete" file="#Dir.Directory[CR]#/#Dir.Name[CR]#">
			</CFLOOP>
		<CFELSE>	
			<CFTRY>
				<CFDIRECTORY action="delete" directory="#RootDir#/images/inuse/#CurrInstance#" recurse="yes">
				<CFDIRECTORY action="delete" directory="#PersistDir#" recurse="yes">
				<CFDIRECTORY action="delete" directory="#SaveDir#" recurse="yes">
			<CFCATCH Type="Any">
				<CFOUTPUT>Unable to delete directories in the /tmp/DiskSpeed mounted volume. You may have the directory locked in a file viewer. Get out and refresh this page.</CFOUTPUT>
				<CFABORT>
			</CFCATCH>
			</CFTRY>
		</CFIF>
	</CFIF>
	<CFIF FORM.SubmitButton NEQ "Purge Manual Drives">
		<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
	</CFIF>
</CFIF>
<!--- Parameter validation --->
<CFIF URL.Controller NEQ "">
	<CFIF StructKeyExists(HW,URL.Controller) EQ "NO">
		<cfoutput>Bad url.controller<br></cfoutput><cfabort>
	</CFIF>
	<CFIF URL.PortNo NEQ "">
		<CFIF IsNumeric(URL.PortNo)>
			<CFIF URL.PortNo GT ArrayLen(HW[URL.Controller].Ports)>
				<CFOUTPUT>Bad URL.PortNo</CFOUTPUT><CFABORT>
			<CFELSE>
				<CFSET DispOutput=0>
			</CFIF>
		<CFELSE>
			<CFOUTPUT>Bad URL.PortNo</CFOUTPUT><CFABORT>
		</CFIF>
	</CFIF>
</CFIF>
<CFIF URL.Drive NEQ "">
	<CFIF StructKeyExists(HW,ListFirst(URL.Drive,"|")) EQ "NO">
		<CFSET URL.Drive="">
		<cfoutput>Bad url.drive<br></cfoutput><cfabort>
	<CFELSE>
		<CFIF IsNumeric(ListLast(URL.Drive,"|")) EQ "NO">
			<CFSET URL.Drive="">
			<cfoutput>Bad url.drive<br></cfoutput><cfabort>
		<CFELSE>
			<CFIF ListLast(URL.Drive,"|") GT ArrayLen(HW[ListFirst(URL.Drive,"|")].Ports)>
				<CFSET URL.Drive="">
				<cfoutput>Bad url.drive<br></cfoutput><cfabort>
			</CFIF>
		</CFIF>
	</CFIF>
</CFIF>
<CFIF ListFindNoCase("Y,N",URL.Benchmark) EQ 0>
	<CFSET URL.Benchmark="N">
	<cfoutput>Bad URL.Benchmark<br></cfoutput><cfabort>
</CFIF>
<CFIF ListFindNoCase("Y,N",URL.BenchmarkDrive) EQ 0>
	<CFSET URL.BenchmarkDrive="N">
	<cfoutput>Bad URL.BenchmarkDrive<br></cfoutput><cfabort>
</CFIF>

<CFIF URL.Drive NEQ "" AND URL.BenchmarkDrive EQ "Y">
	<CFSET HW[ListFirst(URL.Drive,"|")].Ports[ListLast(URL.Drive,"|")].OptimalBlockSize=0>
	<CFSET URL.Benchmark="Y">
	<CFSET URL.BlockSize="Determine Optimal Block Size">
	<CFSET HashDir=HW[ListFirst(URL.Drive,"|")].Ports[ListLast(URL.Drive,"|")].DriveHash>
	<CFDIRECTORY action="list" directory="#PersistDir#/optimize/#HashDir#" type="file" filter="*.txt" name="Dir">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="DELETE" file="#PersistDir#/optimize/#HashDir#/#Dir.Name[CR]#">
	</CFLOOP>
</CFIF>

<CFSET AllDriveIDs="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFSET AllDriveIDs=ListAppend(AllDriveIDs,HW[Key].Ports[PortNo].DriveID)>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFSET AllDriveIDs=ListSort(AllDriveIDs,"text")>


<!--- Check to see if we need to fetch any drive images
<CFSET NeedImage="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].Config.FetchInfo EQ 1>
				<CFSET NeedImage=ListAppend(NeedImage,"#Key#|#PortNo#","~")>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>--->

<!--- <CFQUERY name="CSS" dbtype="query">
	SELECT DISTINCT width, height
	FROM Request.ThumbInfo
	ORDER BY width, height
</CFQUERY>
<CFQUERY name="CSS_H" dbtype="query">
	SELECT DISTINCT height
	FROM Request.ThumbInfo
	ORDER BY height
</CFQUERY> --->

<CFIF DispOutput>
<!--- Generate drive CSS & process drive images --->
<CFSET CSS="">
<CFSET CSSTD="">
<CFSET CSSH="">
<CFSET CSSHN="">
<CFSET CSSHN2="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF StructKeyExists(HW[Key].Ports[PortNo],"CDROM") EQ "NO">
			<CFSET HW[Key].Ports[PortNo].CDROM=0>
		</CFIF>
		<CFIF DriveID NEQ "" AND HW[Key].Ports[PortNo].CDROM EQ 0>
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
					<CFSET OutTextCSS=OutTextCSS & "margin-top:8px;">
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
	</CFLOOP>
</CFLOOP>
<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
	<CFFILE action="write" file="#SaveDir#/drives.css" output="#CSS##CSSTD##CSSHN##CSSHN2#" addnewline="NO" mode="666">
</cflock>

<CFSET DeleteTestFiles()>

<CFINCLUDE TEMPLATE="Styles.cfm">
<CFOUTPUT>
<style type="text/css">
#CSS##CSSTD##CSSHN##CSSHN2#
<!--- <CFLOOP index="CR" from="1" to="#CSS.RecordCount#">
.Thumb_#CSS.Width[CR]#_#CSS.Height[CR]# {width:#CSS.Width[CR]#px; height:#CSS.Height[CR]#px;}
</CFLOOP>
<CFLOOP index="CR" from="1" to="#CSS_H.RecordCount#">
	<CFSET x=CSS.Height[CR] * 2>
.Thumb_#CSS.Width[CR]#_#CSS.Height[CR]#_HN {top:-#CSS.Height[CR]#px;}
.Thumb_#CSS.Width[CR]#_#CSS.Height[CR]#_HN2 {top:-#x#px;}
</CFLOOP>
.Default {color:black; font-size:30px; vertical-align:middle; text-align:center; line-height:175px;}
.WDC {color:white; font-size:20px; vertical-align:middle; text-align:center; line-height:175px;}
.SEA {color:white; font-size:20px; vertical-align:middle; text-align:center; line-height:175px;}
.SAN {color:white; font-size:20px; vertical-align:middle; text-align:center; line-height:175px; -moz-transform:rotate(-90deg); -webkit-transform:rotate(-90deg); -ms-transform:rotate(-90deg); -o-transform:rotate(-90deg); filter:progid:DXImageTransform.Microsoft.BasicImage(rotation=3);}
.SAM1 {color:white; font-size:20px; vertical-align:middle; text-align:center; line-height:115px; -moz-transform:rotate(-90deg); -webkit-transform:rotate(-90deg); -ms-transform:rotate(-90deg); -o-transform:rotate(-90deg); filter:progid:DXImageTransform.Microsoft.BasicImage(rotation=3);}
.MAX {color:black; font-size:20px; vertical-align:middle; text-align:center; line-height:175px; text-shadow:-2px -2px 0 ##fff,2px -2px 0 ##fff,-2px 2px 0 ##fff,2px 2px 0 ##fff;}
##HighCharts_BlockSize {
	height: 300px;
	min-width: 320px;
	max-width: 500px;
	margin: 0 auto;
} --->
</style>
<div id="buymeacoffee" style="position:fixed; bottom: 5px; right: 50px; opacity: 1; cursor: pointer;" title="Buy me a coffee">
	<a href="https://www.buymeacoffee.com/jbartlett0" target="_blank" border="0"><img src="/images/BuyMeACoffee.png"></a>
</div>
<script language="JavaScript">
<CFSET DriveIDs="">
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFSET DriveIDs=ListAppend(DriveIDs,DriveID)>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFLOOP index="DriveID" list="#DriveIDs#">
	var #DriveID#_activity=0;
</CFLOOP>
$.ajaxSetup({ cache: false });
FirstPass=1;
function GetDriveActivity()
{
	$.getJSON("#WebRoot#/isolated/GetDriveActivity.cfm",
	function(data) {
		//console.log(data);
		if (FirstPass == 1)
		{
			FirstPass=0;
			return true;
		}
		<CFLOOP index="DriveID" list="#DriveIDs#">
		if (data.#DriveID# == 0)
		{
			if (#DriveID#_activity != 0)
			{
				#DriveID#_activity=0;
				document.getElementById('Drive_#DriveID#').classList.remove('DriveActive');
			}
		} else {
			if (#DriveID#_activity == 0)
			{
				#DriveID#_activity=data.#DriveID#;
				document.getElementById('Drive_#DriveID#').classList.add('DriveActive');
			}
		}
		</CFLOOP>
	});
	setTimeout(GetDriveActivity,5000);
}
//Disabling drive activity until issues with rotated images is resolved
//GetDriveActivity();
var BrowserWidth = 0, BrowserHeight = 0;
if( typeof( window.innerWidth ) == 'number' ) {
	//Non-IE
	BrowserWidth = window.innerWidth;
	BrowserHeight = window.innerHeight;
} else if( document.documentElement && ( document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
	//IE 6+ in 'standards compliant mode'
	BrowserWidth = document.documentElement.clientWidth;
	BrowserHeight = document.documentElement.clientHeight;
} else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
	//IE 4 compatible
	BrowserWidth = document.body.clientWidth;
	BrowserHeight = document.body.clientHeight;
}
$(document).ready(function() {

});
//alert(window.innerHeight);
var BottomOffset=100;
function UpdateRightDiv(u)
{
	document.getElementById('RightFrame').src=u;
}
</script>
</head>
<body>
</CFOUTPUT>
<CFINCLUDE TEMPLATE="KillDiskPIDs.cfm">
<CFOUTPUT>
<table id="MainTable" border="0" cellpadding="0" cellspacing="0" height="100%" style="max-height:700px;overflow-y:scroll;">
	<tr>
		<td class="Arial Hand NOBR" onClick="location.href='index.cfm'" width="50%" valign="top">
			<div id="HeaderRow">
			<cfinclude template="DispHeader.cfm">
			</div>
		</td>
		<td rowspan="2" class="RightBorder">&nbsp;</td>
		<td rowspan="2">&nbsp;</td>
		<td class="AlignTop" rowspan="2" width="50%">

			<CFSET IFrameURL="DispOverview.cfm">
			<CFIF URL.Drive NEQ "">
				<!--- <CFINCLUDE template="DispDrive.cfm"> --->
				<CFSET IFrameURL="DispDrive.cfm?Drive=#URLEncodedFormat(URL.Drive)#">
			</CFIF>
			<CFIF URL.Controller NEQ "" AND URL.Benchmark NEQ "Y">
				<!--- <CFINCLUDE template="DispController.cfm"> --->
				<CFSET IFrameURL="DispController.cfm?Controller=#URLEncodedFormat(URL.Controller)#">
			</CFIF>

			<script language="JavaScript">
			var LeftDivHeight=window.innerHeight - BottomOffset;
			<!--- document.write('<div id="RightSide" style="overflow-y:scroll;max-height:'+LeftDivHeight+'px;">'); --->
			document.write('<iframe src="#IFrameURL#" width="100%" height="'+LeftDivHeight+'" id="RightFrame" frameBorder="0"></iframe>');
			</script>

		</CFOUTPUT>

		</CFIF>

		<!--- <CFIF NeedImage NEQ "">
			<CFOUTPUT>
			[#NeedImage#]
			<iframe src="GetInitialDriveImage.cfm?Drives=#URLEncodedFormat(NeedImage)#" width="800" height="800"></iframe>
			</CFOUTPUT>
		</CFIF> --->


		<!--- <CFIF URL.Controller EQ "" AND URL.Drive EQ "">
			<CFINCLUDE template="DispOverview.cfm">
		</CFIF> --->




<CFOUTPUT>
			</div>
		</td>
	</tr>
	<tr>
		<td class="AlignTop" id="DiscInfo">
			<script language="JavaScript">
			var LeftDivHeight=window.innerHeight - document.getElementById('HeaderRow').clientHeight - BottomOffset;
			document.write('<div id="DriveList" style="overflow-y:scroll;max-height:'+LeftDivHeight+'px;">');
			</script>
</CFOUTPUT>

<!--- Sort the controllers by name --->
<CFSET ControllerSort=ArrayNew(1)>
<CFSET i=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFSET i=i+1>
	<CFSET ControllerSort[i]=LJustify(HW[Key].Config.Device,255) & "|" & Key>
</CFLOOP>
<CFSET ArraySort(ControllerSort,"textnocase")>
<CFSET KeyList="">
<CFLOOP index="i" from="1" to="#ArrayLen(ControllerSort)#">
	<CFSET KeyList=ListAppend(KeyList,ListLast(ControllerSort[i],"|"))>
</CFLOOP>

<CFSET Loc=ListFindNoCase(KeyList,"Create")>
<CFIF Loc GT 0>
	<CFSET KeyList=ListPrepend(ListDeleteAt(KeyList,Loc),"Create")>
</CFIF>
<CFSET Loc=ListFindNoCase(KeyList,"Unknown")>
<CFIF Loc GT 0>
	<CFSET KeyList=ListAppend(ListDeleteAt(KeyList,Loc),"Unknown")>
</CFIF>
<!--- Move NVMe drives to the end --->
<CFSET OK=0>
<CFSET NVMeList="">
<CFLOOP condition="NOT OK">
	<CFSET OK=1>
	<CFLOOP index="Loc" from="#ListLen(KeyList)#" to="1" step="-1">
		<CFIF StructKeyExists(HW[Key],"NVMe") EQ "NO">
			<!--- Something bad happened, force a rescan --->
			<CFFILE action="delete" file="#PersistDir#/storage.json">
			<CFLOCATION URL="index.cfm" addtoken="NO">
		</CFIF>
		<CFSET Key=ListGetAt(KeyList,Loc)>
		<CFIF HW[Key].NVMe EQ 1>
			<CFSET NVMeList=ListAppend(NVMeList,Key)>
			<CFSET KeyList=ListDeleteAt(KeyList,Loc)>
			<CFSET OK=0>
			<CFBREAK>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFIF NVMeList NEQ "">
	<CFSET KeyList=KeyList & "," & NVMeList>
</CFIF>

<CFSET NVMEHeader=0>
<CFLOOP index="IncNVME" from="0" to="1">
	<CFLOOP index="Key" list="#KeyList#">
		<CFIF HW[Key].USB EQ 0>
			<CFIF HW[Key].NVMe EQ IncNVME>
				<CFIF HW[Key].TotalDrives GT 0>
					<CFINCLUDE template="DispControllerDrive.cfm">
					<CFIF IncNVME EQ 0>
						<CFOUTPUT><br class="BR" /></CFOUTPUT>
						<CFIF Key NEQ ListLast(StructKeyList(HW))>
							<CFOUTPUT><br></CFOUTPUT>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>
<CFSET ChkBr=0>
<CFSET IncNVME=0>
<CFLOOP index="Key" list="#KeyList#">
	<CFIF HW[Key].USB EQ 1>
		<CFIF ChkBr EQ 0>
			<CFSET ChkBr=1>
			<CFOUTPUT><br class="BR" /><br></CFOUTPUT>
		</CFIF>
		<CFIF HW[Key].TotalDrives GT 0>
			<CFINCLUDE template="DispControllerDrive.cfm">
			<CFOUTPUT><br class="BR" /></CFOUTPUT>
			<CFIF Key NEQ ListLast(StructKeyList(HW))>
				<CFOUTPUT><br></CFOUTPUT>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>


<CFIF DiskSpeedDeveloper AND Key EQ "Create">
	<CFPARAM name="URL.DefaultVendor" default="">
	<CFPARAM name="URL.DupeModel" default="">
	<CFPARAM name="URL.ModelExists" default="">
	<CFPARAM name="URL.Model" default="">
	<CFPARAM name="URL.Capacity" default="">
	<CFPARAM name="URL.Clone" default="">
	<CFOUTPUT>
	<form action="AddBlankDrive.cfm" method="POST">
	Vendor:
	<select name="Vendor" size="1">
		<option value=""></option>
		<CFLOOP index="CurrItem" list="#VendorList#">
			<CFIF URL.DefaultVendor EQ CurrItem>
				<option value="#CurrItem#" SELECTED>#CurrItem#</option>
			<CFELSE>
				<option value="#CurrItem#">#CurrItem#</option>
			</CFIF>
		</CFLOOP>
	</select>
	&nbsp;&nbsp;&nbsp;
	Model: <input type="text" name="Model" value="#URL.Model#" size="15">&nbsp;&nbsp;&nbsp;
	Clone: <input type="text" name="Clone" value="#URL.Clone#" size="15">&nbsp;&nbsp;&nbsp;
	Capacity: <input type="text" name="Capacity" size="4" value="#URL.Capacity#" size="3">&nbsp;&nbsp;&nbsp;
	<input type="submit" value="Add Drive"><br>
	<CFIF URL.DupeModel EQ "Y">
		<span class="Bold Red">Warning:</span> Model already exists - <input type="Checkbox" name="AddAnyway" value="Y"> Add Anyway<br><br>
	</CFIF>
	<CFIF URL.ModelExists EQ "Y">
		<span class="Bold Red">Error:</span> Model already added<br><br>
	</CFIF>
	</form>
	</CFOUTPUT>
</CFIF>

<CFIF NVMEHeader EQ 1>
	<CFOUTPUT><br class="BR" /></CFOUTPUT>
</CFIF>

<CFLOOP index="Key" list="#KeyList#">
	<CFIF HW[Key].TotalDrives EQ 0>
		<CFINCLUDE TEMPLATE="DispControllerInfo.cfm">
		<CFOUTPUT><span class="Size12">No drives detected</span><br><br><br></CFOUTPUT>
	</CFIF>
</CFLOOP>

<CFOUTPUT>
		</td>
</CFOUTPUT>
<CFIF DispOutput>
		<CFOUTPUT>
	</tr>
</table>
</div>
<hr>
<form action="index.cfm" method="POST">
<input type="Hidden" name="ScanControllers" value="Y">
<input type="Submit" name="SubmitButton" value="Rescan Controllers">&nbsp;&nbsp;&nbsp;
<input type="Submit" name="SubmitButton" value="Purge Everything and Start Over" onclick="return confirm('Are you sure? All data such as Benchmarks will be removed.')" >&nbsp;&nbsp;&nbsp;
<CFIF StructKeyExists(HW,"Create")>
	<input type="Submit" name="SubmitButton" value="Purge Manual Drives">&nbsp;&nbsp;&nbsp;
</CFIF>
</CFOUTPUT>
<CFFLUSH>
<!--- Check to see if we should display the upload button --->
<CFSET DispButton=0>
<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFIF HW[Key].USB EQ 0>
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
				<CFIF HW[Key].Ports[PortNo].HDDBFound EQ 0>
					<CFSET DispButton=1>
					<CFBREAK>
				</CFIF>
				<CFSET DriveDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>
				<CFSET BenchDir=DriveDir & "/benchmark">
				<CFIF FileExists("#DriveDir#/nosubmit.txt") EQ 0>
					<CFDIRECTORY action="list" directory="#BenchDir#" name="BenchData" type="Dir">
					<CFLOOP index="BenchIdx" from="1" to="#BenchData.RecordCount#">
						<CFIF FileExists("#BenchDir#/#BenchData.Name[BenchIdx]#/submitted.txt") EQ "NO">
							<CFSET DispButton=1>
							<CFBREAK>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
			<CFIF DispButton EQ 1>
				<CFBREAK>
			</CFIF>
		</CFLOOP>
	</CFIF>
	<CFIF DispButton EQ 1>
		<CFBREAK>
	</CFIF>
</CFLOOP>
<CFIF DispButton>
	<CFOUTPUT>
	<button type="button" onClick="this.style.display='none';" data-fancybox data-type="iframe" data-src="isolated/UploadDriveData.cfm">Upload Drive &amp; Benchmark Data to the Hard Drive Database</button><br>
	</CFOUTPUT>
</CFIF>
<CFOUTPUT>
</form>
<span class="Size14 Red Hand Underline" data-fancybox data-type="iframe" data-src="/changelog.html?x=#GetTickCount()#">Change Log</span>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<span class="Size14 Hand Underline" data-fancybox data-type="iframe" data-src="/isolated/CreateDebugInfo.cfm?x=#GetTickCount()#">Create Debug File</span>
<CFIF FileExists("/usr/local/tomcat/lib/seefusion5-2.jar")>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<a href="http://192.168.10.7:18889/" target="SeeFusion">SeeFusion</a>
</CFIF>
<br>
</CFOUTPUT>
</CFIF>


<CFIF DispOutput>
	<CFIF DiskSpeedDeveloper AND StructKeyExists(HW,"Create") EQ "NO">
		<CFPARAM name="URL.DefaultVendor" default="">
		<CFPARAM name="URL.DupeModel" default="">
		<CFPARAM name="URL.ModelExists" default="">
		<CFPARAM name="URL.Model" default="">
		<CFPARAM name="URL.Capacity" default="">
		<CFPARAM name="URL.Clone" default="">
		<CFOUTPUT>
		<br>
		<form action="AddBlankDrive.cfm" method="POST">
		Vendor:
		<select name="Vendor" size="1">
			<option value=""></option>
			<CFLOOP index="CurrItem" list="#VendorList#">
				<CFIF URL.DefaultVendor EQ CurrItem>
					<option value="#CurrItem#" SELECTED>#CurrItem#</option>
				<CFELSE>
					<option value="#CurrItem#">#CurrItem#</option>
				</CFIF>
			</CFLOOP>
		</select>
		&nbsp;&nbsp;&nbsp;
		Model: <input type="text" name="Model" value="#URL.Model#" size="15">&nbsp;&nbsp;&nbsp;
		Clone: <input type="text" name="Clone" value="#URL.Clone#" size="15">&nbsp;&nbsp;&nbsp;
		Capacity: <input type="text" name="Capacity" size="4" value="#URL.Capacity#" size="3">&nbsp;&nbsp;&nbsp;
		<input type="submit" value="Add Drive"><br>
		<CFIF URL.DupeModel EQ "Y">
			<span class="Bold Red">Warning:</span> Model already exists - <input type="Checkbox" name="AddAnyway" value="Y"> Add Anyway<br><br>
		</CFIF>
		<CFIF URL.ModelExists EQ "Y">
			<span class="Bold Red">Error:</span> Model already added<br><br>
		</CFIF>
		</form>
		</CFOUTPUT>
	</CFIF>


	<CFIF DiskSpeedDeveloper>
		<CFOUTPUT>
		Instance: #CurrInstance#
		</CFOUTPUT>
		<CFIF StructKeyExists(HW,"Create")><CFDUMP var=#hw# show="create"></CFIF>
		<CFDUMP var=#hw#>
		<cfdump var=#ref#>
		<cfdump var=#HWTree#>
		<CFDUMP var=#USBTree#>
		<cfdump var=#MiscRef#>
	</CFIF>

	<!--- <CFSET JavaObj=createobject("java","java.lang.Runtime").getRuntime()>
	<CFOUTPUT>
	Total Memory: #NumberFormat(JavaObj.totalMemory(),"9,999")#<br>
	Free memory: #NumberFormat(JavaObj.freeMemory(),"9,999")#<br>
	Max Memory: #NumberFormat(JavaObj.maxMemory(),"9,999")#<br>
	<hr>
	</CFOUTPUT>
	<CFOUTPUT>
	<CFSET JavaObj.gc()>
	<CFSET JavaObj.runFinalization()>
	Total Memory: #NumberFormat(JavaObj.totalMemory(),"9,999")#<br>
	Free memory: #NumberFormat(JavaObj.freeMemory(),"9,999")#<br>
	Max Memory: #NumberFormat(JavaObj.maxMemory(),"9,999")#<br>
	</CFOUTPUT> --->


	<CFOUTPUT>
	</body>
	</html>
	</CFOUTPUT>

</CFIF>


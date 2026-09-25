<CFPARAM name="variables.NoHeader" default="0">

<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
<CFELSE>
	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>

<CFIF StructKeyExists(Ref.DriveID,URL.Drive) EQ "NO">
	<CFABORT>
</CFIF>
<CFSET Key=Ref.DriveID[URL.Drive].Key>
<CFSET PortNo=Ref.DriveID[URL.Drive].PortNo>
<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>

<CFFILE action="read" file="#SaveDir#/drives.css" variable="DriveCSS">

<CFSET HeatDir=PersistDir & "/driveinfo/" & Drive.Config.SaveDir & "/surfacescan">
<CFIF DirectoryExists(HeatDir) EQ "NO">
	<CFDIRECTORY action="create" directory="#HeatDir#" mode="666">
</CFIF>

<CFIF NoHeader EQ 0>
	<CFOUTPUT>
	<!DOCTYPE html>
	<html>
	<head>
	<title>DiskSpeed</title>
	<script type="text/javascript" src="/includes/jquery-3.2.1.min.js"></script>
	<!--- <script type="text/javascript" src="#Highstocks#/highstock.js"></script> --->
	<!--- <script type="text/javascript" src="#HighchartsBoost#"></script> --->
	<!---<script type="text/javascript" src="#Highmaps#/modules/map.js"></script>--->
	<!---<script type="text/javascript" src="#Highstocks#/modules/data.js"></script>--->
	<script src="#Highcharts#/highcharts.js"></script>
	<script src="#Highcharts#/modules/heatmap.js"></script>
	<script src="#Highcharts#/modules/exporting.js"></script>
	<script src="#Highcharts#/modules/boost.js"></script>
	<script src="#Highcharts#/modules/no-data-to-display.js"></script>

	<style type="text/css">
	body {font-family:Arial, Helvetica, sans-serif;}
	td {font-family:Arial, Helvetica, sans-serif;}
	.Bold {font-weight:bold;}
	.Size5 {font-size:5px;}
	.Size12 {font-size:12px;}
	.Size14 {font-size:14px;}
	.Size18 {font-size:18px;}
	.Size24 {font-size:24px;}
	.Black {color:black;}
	.Grey {color:909090;}
	.White {color:white;}
	.Red {color:red;}
	.OuterBox {float:left;margin-right:5px;margin-bottom:5px;}
	.Box {border:0px}
	.FloatLeft {float:left;}
	.Hand {cursor:pointer;}
	.DefaultCursor {cursor:default;}
	.AlignTop {vertical-align:top;}
	.BR {clear:left;}
	.NOBR {white-space:nowrap;}
	.Hidden {display:none !important;}
	.USBTreeHidden {display:none !important;}
	.KindaHidden { opacity: 0.01;}
	.RightBorder {border-right:thin solid ##909090;}
	.MainDivTable {display:table;width:100%;}
	.MainDivRow {display:table-row;}
	.MainDivCell {display:table-cell;width:50%;}
	.DivTable {display:table;}
	.DivRow {display:table-row;}
	.DivCell {display:table-cell;}
	.Picture {margin-right:3px;float:left;margin-bottom:3px;}
	.Overlay {position:relative; left:0px; z-index:10;}
	.Overlay2 {position:absolute; left:0px; z-index:9;}
	.OverlayLink {position:relative; left:0px; z-index:8;}
	.Details {font-size:12px;width:128px;}
	.ClipOverflow {overflow:hidden;text-overflow:ellipsis;}
	.Underline {text-decoration:underline;}
	.DriveActive {outline-style:solid;outline-color:red;}
	.slider-vwrapper {display:inline-block; width:20px; height:150px; padding:0;}
	.slider-vwrapper input {width:150px; height:20px; margin:0; transform-origin:75px 75px; transform:rotate(-90deg);}
	.Nav2 {background-image:url('/images/DirNav2a.gif');background-position:top;background-repeat:no-repeat;width:16px;}
	.Nav3 {background-image:url('/images/DirNav3.gif');background-position:top;background-repeat:no-repeat;width:16px;}
	#DriveCSS#
	</style>
	</head>
	<body>
	</CFOUTPUT>
	<CFSET NoEdit="Y">
	<CFSET DoNotDisplaySMARTInfo="Y">
	<CFINCLUDE template="DispDriveInfo.cfm">
</CFIF>

<!--- <cfoutput>#HeatDir#</cfoutput> --->

<CFSET ChunkSize=Int(10000000000 / Drive.OptimalBlockSize)> <!--- How many blocks in 10 gig --->
<CFSET TotalChunks=Int(Drive.Attrib.Size.Bytes / Drive.OptimalBlockSize)>
<CFIF FileExists("#HeatDir#/xxxxxSpeedData.wddx")>
	<CFFILE action="read" file="#HeatDir#/SpeedData.wddx" variable="json">
	<cfwddx input="#json#" output="SpeedData" action="wddx2cfml">
<CFELSE>
	<CFSET SpeedData=ArrayNew(1)>
	<CFSET ArraySet(SpeedData,1,TotalChunks+1,-1)>
	<CFIF FileExists("#HeatDir#/BadBlocks.txt")>
		<CFFILE action="Delete" file="#HeatDir#/BadBlocks.txt">
	</CFIF>
</CFIF>

<CFSET GroupedBlocks=ArrayNew(1)>

<CFDIRECTORY action="list" directory="#HeatDir#" filter="0*.spot" name="SpotDir">
<CFDIRECTORY action="list" directory="#HeatDir#" filter="0*.scan" name="Dir">

<CFIF Dir.RecordCount GT 0 OR SpotDir.RecordCount GT 0>
	<CFOUTPUT><div id="Parsing">Parsing scan data...</div></CFOUTPUT><CFFLUSH>
</CFIF>

<CFSET LastAvg=-1>
<CFLOOP index="CR" from="1" to="#SpotDir.RecordCount#">
	<CFSET Avg=int(CR / SpotDir.RecordCount / 0.01)>
	<CFIF Avg NEQ LastAvg>
		<CFSET LastAvg=Avg>
		<CFOUTPUT><script>document.getElementById('Parsing').innerHTML='Parsing scan data... (#Avg#%)';</script></CFOUTPUT><CFFLUSH>
	</CFIF>
	<CFFILE action="Read" file="#HeatDir#/#SpotDir.Name[CR]#" variable="Results">
	<CFSET SpeedData[Val(ListFirst(SpotDir.Name[CR],"."))+1]=Val(ParseSpotScan(Results))>
</CFLOOP>

<!--- <CFDUMP var=#SpeedData#><cfabort> --->

<CFSET HeatMapJSON="">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFSET ParseSurfaceScan(SpeedData,"#HeatDir#/#Dir.Name[CR]#",Drive.OptimalBlockSize,ChunkSize,0)>
</CFLOOP>
<!--- <cfdump var=#speeddata#><cfabort> --->
<CFSET ShrinkDriveBlocks(HeatmapGroupCap,Drive.Attrib.Size.Bytes,Drive.OptimalBlockSize)>
<!--- <cfdump var=#GroupedBlocks#><cfabort> --->

<CFIF Dir.RecordCount GT 0 OR SpotDir.RecordCount GT 0>
	<cfwddx input="#SpeedData#" output="json" action="cfml2wddx">
	<CFFILE action="write" file="#HeatDir#/SpeedData.wddx" output="#json#" addnewline="NO" mode="666">
	<CFOUTPUT><script>document.getElementById('Parsing').innerHTML='Building Heatmap Data...';</script></CFOUTPUT><CFFLUSH>
	<CFSET HeatMapJSON=BuildSpeedMap(1000,Drive.OptimalBlockSize,HeatmapGroupCap,Drive.Attrib.Size.Bytes)>
	<CFFILE action="write" file="#HeatDir#/Heatmap_#Drive.OptimalBlockSize#.json" output="#HeatMapJSON#" addnewline="NO" mode="666">
</CFIF>
<CFOUTPUT><script>document.getElementById('Parsing').style.display='none';</script></CFOUTPUT><CFFLUSH>

<CFIF Dir.RecordCount GT 0>
	<CFOUTPUT><script>document.getElementById('Parsing').style.display='none';</script></CFOUTPUT><CFFLUSH>
</CFIF>
<CFIF HeatMapJSON EQ "">
	<CFIF FileExists("#HeatDir#/Heatmap_#Drive.OptimalBlockSize#.json")>
		<CFFILE action="read" file="#HeatDir#/Heatmap_#Drive.OptimalBlockSize#.json" variable="HeatMapJSON">
	</CFIF>
</CFIF>

<CFSET MinSpeed=0>
<CFSET MaxSpeed=0>
<CFIF FileExists("#HeatDir#/MinSpeed.txt")>
	<CFFILE action="read" file="#HeatDir#/MinSpeed.txt" variable="MinSpeed">
</CFIF>
<CFIF FileExists("#HeatDir#/MaxSpeed.txt")>
	<CFFILE action="read" file="#HeatDir#/MaxSpeed.txt" variable="MaxSpeed">
</CFIF>

<!--- <cfoutput>#MinSpeed#-#MaxSpeed#</cfoutput> --->
<CFINCLUDE template="DispHeatmap.cfm">

<CFOUTPUT>
<form action="index.cfm" method="GET">
<input type="Hidden" name="Drive" value="#Key#|#PortNo#">
<input type="Submit" value="Go Back">
</form>
</CFOUTPUT>

<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>


<CFOUTPUT>
<xiframe src="SurfaceScanAction.cfm?Drive=#URL.Drive#" width="1000" height="500">
</CFOUTPUT>
<cfdump var=#Drive#>


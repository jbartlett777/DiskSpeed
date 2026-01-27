<CFQUERY name="Revisions" datasource="#DSN#">
	SELECT m.*
	FROM DiskSpeed.Models m
	LEFT JOIN DiskSpeed.Vendors v ON (m.VendorID=v.ID)
	WHERE v.Vendor=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#URL.Vendor#">
	  AND m.Model=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#URL.Model#">
	ORDER BY Revision
</CFQUERY>

<!--- <cfdump var=#revisions#> --->

<CFSET Path="/diskspeed/Drives/" & URL.Vendor & "/" & URL.Model>
<CFIF DirectoryExists("#ParentDir#/#Path#")>
	<CFDIRECTORY action="list" directory="#ParentDir#/#Path#" name="PNG" filter="*.png" type="file" sort="datelastmodified">
	<CFSET Thumbnail=Path & "/" & PNG.Name[1]>
<CFELSE>
	<CFSET Thumbnail="">
</CFIF>

<CFOUTPUT>
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Model-Database-2 - HDDB</title>
    <meta property="og:title" content="Model-Database-2 - HDDB" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta charset="utf-8" />

<link rel="stylesheet" href="/includes/toastui/toastui-chart.min.css" />
<script src="/includes/toastui/toastui-chart.min.js"></script>
<script>
const chart = toastui.Chart;
</script>
<style>
body, td {
	color: white;
	font-size: 14px;
	font-family: sans-serif;
}
.Arial {font-family:Arial, Helvetica, sans-serif;}
.Bold {font-weight:bold;}
.Size5 {font-size:5px;}
.Size12 {font-size:12px;}
.Size14 {font-size:14px;}
.Size18 {font-size:18px;}
.Size24 {font-size:24px;}
.Size40 {font-size:40px;}
.Size90 {font-size:90px;}
.Black {color:black;}
.Grey {color:##999;}
.LightGrey {color:##DDD;}
.Yellow {color:yellow;}
.Green {color:green;}
.White {color:white;}
.Red {color:red;}
.BR {clear:left;}
.NoLink {text-decoration:none;}
.Underline {text-decoration:underline;}
.NOBR {white-space:nowrap;}
.Center {text-align:center;}
.Right {text-align:right;}
.FloatLeft {float:left;}
.Margin10 {margin:10px;}
.Margin20 {margin:20px;}
.ImgBox {min-height:236px;}
.CursorPointer {cursor:pointer;}
.Hidden {display:none;}
</style>
<style data-tag="reset-style-sheet">
	html {  line-height: 1.15;}body {  margin: 0;}* {  box-sizing: border-box;  border-width: 0;  border-style: solid;}p,li,ul,pre,div,h1,h2,h3,h4,h5,h6,figure,blockquote,figcaption {  margin: 0;  padding: 0;}button {  background-color: transparent;}button,input,optgroup,select,textarea {  font-family: inherit;  font-size: 100%;  line-height: 1.15;  margin: 0;}button,select {  text-transform: none;}button,[type="button"],[type="reset"],[type="submit"] {  -webkit-appearance: button;}button::-moz-focus-inner,[type="button"]::-moz-focus-inner,[type="reset"]::-moz-focus-inner,[type="submit"]::-moz-focus-inner {  border-style: none;  padding: 0;}button:-moz-focus,[type="button"]:-moz-focus,[type="reset"]:-moz-focus,[type="submit"]:-moz-focus {  outline: 1px dotted ButtonText;}a {  color: inherit;  text-decoration: inherit;}input {  padding: 2px 4px;}img {  display: block;}html { scroll-behavior: smooth  }
</style>
<style data-tag="default-style-sheet">
	html {
	font-family: Inter;
	font-size: 14px;
	}

	body {
	font-weight: 400;
	font-style:normal;
	text-decoration: none;
	text-transform: none;
	letter-spacing: normal;
	line-height: 1.15;
	color: var(--dl-color-gray-black);
	background-color: ##00000000;

	null
	}
</style>
<link
	rel="stylesheet"
	href="https://unpkg.com/animate.css@4.1.1/animate.css"
/>
<link
	rel="stylesheet"
	href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&amp;display=swap"
	data-tag="font"
/>
<link
	rel="stylesheet"
	href="Templates/style.css"
/>

</head>
<body>
<span class="Size24 Arial White">
<CFIF ListFirst(URL.Model," ") EQ URL.Vendor>
	#EncodeForHTML(URL.Model)#<br>
<CFELSE>
	#EncodeForHTML(URL.Vendor)# #EncodeForHTML(URL.Model)#<br>
</CFIF>
</span><br><br>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<CFIF Thumbnail NEQ "">
			<td valign="top"><img src="#Thumbnail#"></td>
			<td>&nbsp;&nbsp;&nbsp;</td>
		</CFIF>
		<td valign="top">
			<span class="Size18 Arial Bold White"><span class="Bold">
			Revision<br>
			Capacity<br>
			<CFIF Val(Revisions.SSD[1]) EQ 0>
				RPM<br>
			</CFIF>
			Signaling Speed<br>
			Sector Size</span> (Log/Phy)<span class="Bold"><br>
			Multiple Sector Transfer<br>
			<CFIF Val(Revisions.SSD[1]) EQ 1>
				Max Transfer Speed/Sec<br>
				Number of Benchmarks
			</CFIF>
			</span></span>
		</td>
		<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		</CFOUTPUT>
		<CFLOOP index="CR" from="1" to="#Revisions.RecordCount#">
			<!--- KBytes returns 9.99 XB format, drop decimal --->
			<CFSET DispCapacity=KBytes(Revisions.Capacity[CR])>
			<CFSET DispCapacity=NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," ")>
			<CFIF Val(Revisions.SSD[1]) EQ 1>
				<!--- Get the highest reported read speed for the SSD --->
				<CFQUERY name="SSDSPeed" datasource="#DSN#">
					SELECT Max(t.Speed) AS MaxSpeed
					FROM DiskSpeed.Benchmarks t
					WHERE BenchmarkID IN (
						SELECT DISTINCT b.ID
						FROM DiskSpeed.BenchmarkID b
						WHERE b.ModelID=#Revisions.ModelID[CR]#
					)
				</CFQUERY>
				<!--- Get total Benchmarks on this drive --->
				<CFQUERY name="TotalBenchmarks" datasource="#DSN#">
					SELECT DISTINCT BenchmarkID
					FROM DiskSpeed.Benchmarks t
					WHERE BenchmarkID IN (
						SELECT DISTINCT b.ID
						FROM DiskSpeed.BenchmarkID b
						WHERE b.ModelID=#Revisions.ModelID[CR]#
					)
				</CFQUERY>
			</CFIF>
			<CFOUTPUT>
			<td valign="top">
				<span class="Size18 Arial White NOBR">
				<span class="Underline">#Revisions.Revision[CR]#</span><br>
				#DispCapacity#<br>
				<CFIF Revisions.SSD[1] NEQ "1">
					<CFIF Val(Revisions.RPM[CR]) EQ 0>
						N/A<br>
					<CFELSE>
						#Revisions.RPM[CR]#<br>
					</CFIF>
				</CFIF>
				<CFIF Trim(Revisions.SignalingSpeed[CR]) EQ "">
					N/A<br>
				<CFELSE>
					#Revisions.SignalingSpeed[CR]#<br>
				</CFIF>
				#Revisions.LogicalSectorSize[CR]#/#Revisions.PhysicalSectorSize[CR]#<br>
				<CFIF Val(Revisions.MultipleSectorTransfer[CR]) EQ 0>
					N/A<br>
				<CFELSE>
					#Revisions.MultipleSectorTransfer[CR]#<br>
				</CFIF>
				<CFIF Val(Revisions.SSD[1]) EQ 1>
					<CFIF IsNumeric(SSDSPeed.MaxSpeed[1])>
						#KBytes(SSDSpeed.MaxSpeed)#<br>
						#TotalBenchmarks.RecordCount#
					<CFELSE>
						N/A
					</CFIF>
				</CFIF>
				</span>
			</td>
			<CFIF CR LT Revisions.RecordCount>
				<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
			</CFIF>
			</CFOUTPUT>
		</CFLOOP>
		<CFOUTPUT>
	</tr>
</table>
</CFOUTPUT>
<CFSET JS="">
<CFIF Val(Revisions.SSD[1]) EQ 0>
	<CFSET GraphID=0>
	<CFOUTPUT>
	<br>
	<div id="Disclaimer" class="Size14 Arial White Hidden" style="width:50%;">
	The following benchmarks are the reported read speeds per second by different units of the same model taken every 10% of the drive's capacity (including at the start & end
	of the drive) for a duration of 15 seconds and then averaged. Tight groupings represents consistant speeds between units.
	Variances with dips represent drives that have failing media which slowed down the time it took to read that spot.
	Graph lines (if any) lower than the rest or are mostly flat were connected to a slow storage controller.<br>
	<br>
	</div>
	<div class="BR"/>
	</CFOUTPUT>
	<!--- Generate graphs per drive revision --->
	<CFSET xAxis="Location">
	<CFLOOP index="CR" from="1" to="#Revisions.RecordCount#">
		<!--- Fetch all benchmark tests with a test of 10% (11 spots) for the drive, only fetching the most recent benchmark for that particular drive --->
		<CFSET AltGraph=0>
		<CFQUERY name="Bench" datasource="#DSN#">
			SELECT t.BenchmarkID, t.Spot, t.Speed
			FROM DiskSpeed.Benchmarks t
			WHERE BenchmarkID IN (
				SELECT DISTINCT b.ID
				FROM DiskSpeed.BenchmarkID b
				WHERE b.ModelID=#Revisions.ModelID[CR]#
				  AND b.DateStamp=(SELECT MAX(DateStamp) FROM DiskSpeed.BenchmarkID WHERE UserID=b.UserID AND DriveID=b.DriveID)
			)
			  AND (SELECT COUNT(*) FROM DiskSpeed.Benchmarks WHERE BenchmarkID=t.BenchmarkID)=11
		</CFQUERY>
		<CFIF Bench.RecordCount EQ 0>
			<CFSET AltGraph=1>
			<CFQUERY name="Bench" datasource="#DSN#">
				SELECT t.BenchmarkID, t.Spot, t.Speed
				FROM DiskSpeed.Benchmarks t
				WHERE BenchmarkID IN (
					SELECT DISTINCT b.ID
					FROM DiskSpeed.BenchmarkID b
					WHERE b.ModelID=#Revisions.ModelID[CR]#
					  AND b.DateStamp=(SELECT MAX(DateStamp) FROM DiskSpeed.BenchmarkID WHERE UserID=b.UserID AND DriveID=b.DriveID)
				)
			</CFQUERY>
		</CFIF>
		<CFIF Bench.RecordCount EQ 0>
			<CFBREAK>
		</CFIF>
		<!--- Get list of benchmarks --->
		<CFQUERY name="TestID" dbtype="query">
			SELECT DISTINCT BenchmarkID FROM Bench ORDER BY BenchmarkID
		</CFQUERY>
		<!--- Loop over benchmarks and build series data --->
		<CFSET Series="">
		<CFSET HeatMap="">
		<CFSET MaxSize=0>
		<CFSET MaxSpeed=0>
		<CFSET SecondScale="">
		<CFLOOP index="i" from="1" to="#TestID.RecordCount#">
			<CFSET Categories="">
			<!--- Fetch Benchmark results --->
			<CFQUERY name="Test" dbtype="Query">
				SELECT Spot, Speed
				FROM Bench
				WHERE BenchmarkID=#TestID.BenchmarkID[i]#
				ORDER BY Spot
			</CFQUERY>
			<CFSET Data="">
			<CFSET HeatMapData="">
			<CFLOOP index="speedidx" from="1" to="#Test.RecordCount#">
				<!--- Wait to build the 1st category until we're at the 2nd one so we can use the same MB/GB/TB scale, prevents it from saying "0 bytes" --->
				<CFIF speedidx EQ 2>
					<CFSET CatTitle=KBytes(Test.Spot[speedidx],"0.0","MB,GB")>
					<CFSET Categories=ListAppend(Categories,"'0 " & ListLast(CatTitle," ") & "','" & CatTitle & "'")>
				<CFELSEIF speedidx GTE 3>
					<CFSET CatTitle=KBytes(Test.Spot[speedidx],"0.0","MB,GB")>
					<CFSET Categories=ListAppend(Categories,"'" & CatTitle & "'")>
				</CFIF>
				<CFIF Test.Spot[speedidx] GT MaxSize>
					<CFSET MaxSize=Test.Spot[speedidx]>
				</CFIF>
				<CFIF Test.Speed[speedidx] GT MaxSpeed>
					<CFSET MaxSpeed=Test.Speed[speedidx]>
				</CFIF>
				<!---<CFSET Data=ListAppend(Data,"[" & Test.Spot[speedidx] & "," & Int(Test.Speed[speedidx]) & "]")>--->
				<CFSET Data=ListAppend(Data,Int(Test.Speed[speedidx]))>
				<!---<CFSET HeatmapData=ListAppend(HeatmapData,"[" & Int(Test.Speed[speedidx]) & "]")>--->
			</CFLOOP>
<!---		<CFSET Series=ListAppend(Series,"{name: 'Test #TestID.BenchmarkID[i]#', type: 'spline', data: [#Data#]}" & Chr(10))>
			<CFSET HeatMap=ListAppend(HeatMap,"{name: 'Test #TestID.BenchmarkID[i]#', data: [#HeatMapData#]}" & Chr(10))>
--->
			<CFSET Series=ListAppend(Series,"{name:'Test #TestID.BenchmarkID[i]#',data:[#Data#]}")>
		</CFLOOP>
		<CFSET GraphID=GraphID+1>
		<CFSET GraphTitle="Drive Speeds for model #Revisions.Revision[CR]#">
		<CFSET GraphSubTitle="Benchmark Scores for " & Trim(NumberFormat(TestID.RecordCount,"9,999")) & " drive">
		<CFIF TestID.RecordCount NEQ 1><CFSET GraphSubTitle=GraphSubTitle & "s"></CFIF>
		<CFSET MaxY=Int(MaxSpeed / 25000000) * 25000000 + 25000000>
		<!--- <CFINCLUDE TEMPLATE="DispModelInfoGraph.cfm"> --->
		<CFIF TestID.RecordCount LTE 10>
			<CFSET SeriesAlpha="80">
		<CFELSEIF TestID.RecordCount LTE 50>
		<CFSET SeriesAlpha="40">
		<CFELSEIF TestID.RecordCount LTE 500>
			<CFSET SeriesAlpha="0f">
		<CFELSE>
			<CFSET SeriesAlpha="08">
		</CFIF>

		<CFOUTPUT>
		<div class="FloatLeft" style="width:800px;">
			<table border="0" cellpadding="0" cellspacing="0" width="100%" height="100%">
				<tbody>
					<tr>
						<td align="center">
							<div id="Graph#GraphID#" class="BenchmarkGraph"></div>
							<CFINCLUDE TEMPLATE="DispModelInfoParallel.cfm">
							#GraphSubTitle#<br>
							<br><br>
						</td>
					</tr>
				</tbody>
			</table>
		</div>
		<!---<CFOUTPUT><div class="BR"></div></CFOUTPUT>--->
		</CFOUTPUT>
	</CFLOOP>


	<CFIF GraphID GT 0>
		<CFOUTPUT>
		<script>document.getElementById('Disclaimer').style.display='block';</script>
		</CFOUTPUT>
	<CFELSE>
		<CFOUTPUT>
		<span class="Size14 Arial White">Benchmark data has not been uploaded for this drive.</span>
		</CFOUTPUT>
	</CFIF>
</CFIF>
<CFIF JS NEQ "">
	<CFOUTPUT>
	#JS#
	</CFOUTPUT>
</CFIF>

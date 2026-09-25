<CFSET SeriesOut="">
<CFIF FileExists("#PersistDir#/driveinfo/DriveBenchmarks.txt")>
	<CFTRY>
		<CFFILE action="read" file="#PersistDir#/driveinfo/DriveBenchmarks.txt" variable="SeriesData">
		<CFSET MaxSize=ListGetAt(SeriesData,1,"|",true)>
		<CFSET SSDsExist=ListGetAt(SeriesData,2,"|",true)>
		<CFSET MaxSSDSpeed=ListGetAt(SeriesData,3,"|",true)>
		<CFSET SSDScript=ListGetAt(SeriesData,4,"|",true)>
		<CFSET SeriesOut=ListGetAt(SeriesData,5,"|",true)>
	<CFCATCH Type="Any1">
	</CFCATCH>
	</CFTRY>
<CFELSE>
	<CFSET MaxSize=0>
	<CFSET MaxSSDSpeed=0>
	<CFSET SSDScript="">
	<CFSET CheckDrives="">
	<CFLOOP index="Key" list="#StructKeyList(HW)#">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
			<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
			<CFIF DriveID NEQ "" AND HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFIF HW[Key].Ports[PortNo].Attrib.Size.Bytes GT MaxSize>
					<CFSET MaxSize=HW[Key].Ports[PortNo].Attrib.Size.Bytes>
				</CFIF>
				<CFSET Label=HW[Key].Ports[PortNo].UNRAIDSlot>
				<CFIF Left(Label,6) EQ "Parity">
					<CFSET Label2="1|" & Label>
				<CFELSEIF Left(Label,5) EQ "Disk ">
					<CFSET Label2="2|" & Label>
				<CFELSEIF Left(Label,5) EQ "Cache">
					<CFSET Label2="3|" & Label>
				<CFELSE>
					<CFIF Label EQ "">
						<CFSET Label2="4|zzzzzzzzzzzzzzzzz" & Label>
					<CFELSE>
						<CFSET Label2="4|" & Label>
					</CFIF>
				</CFIF>
				<CFSET Label2=LJustify(Label2,50)>
				<CFSET CheckDrives=ListAppend(CheckDrives,"#Label2#|#DriveID#")>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
	<CFSET NMinus=Int(MaxSize * 0.10)> <!--- minus 10% X per SSD --->
	<CFSET RMinus=Int(MaxSize * 0.02)> <!--- minus 2% X for read from write --->
	<CFSET SSDSpot=MaxSize - NMinus>

	<CFSET CheckDrives=ListSort(CheckDrives,"text")>
	<CFSET SeriesOut="">
	<CFSET SSDsExist=0>
	<CFSET SeriesIndex=-1>

	<CFLOOP index="CurrDrive" list="#CheckDrives#">
		<CFSET tmpDriveID=Trim(ListGetAt(CurrDrive,3,"|",true))>
		<CFSET tmpLabel=Trim(ListGetAt(CurrDrive,2,"|",true))>
		<CFIF tmpLabel EQ "zzzzzzzzzzzzzzzzz">
			<CFSET tmpLabel=tmpDriveID>
		</CFIF>

		<CFSET Key=Ref.DriveID[tmpDriveID].Key>
		<CFSET PortNo=Ref.DriveID[tmpDriveID].PortNo>
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
			<CFIF FileExists("#BenchmarksDir#/#UseBenchDir#/SSDReadSpeed.txt")>
				<CFSET SeriesIndex=SeriesIndex + 1>
				<CFSET SSDsExist=1>
				<CFSET SSDRead=ReadFile("#BenchmarksDir#/#UseBenchDir#/SSDReadSpeed.txt")>
				<CFSET SSDWrite=ReadFile("#BenchmarksDir#/#UseBenchDir#/SSDWriteSpeed.txt")>
				<CFSET ReadAvg=ListFirst(SSDRead,"|")>
				<CFSET ReadMin=ListGetAt(SSDRead,2,"|")>
				<CFSET ReadMax=ListLast(SSDRead,"|")>
				<CFSET WriteAvg=ListFirst(SSDWrite,"|")>
				<CFSET WriteMin=ListGetAt(SSDWrite,2,"|")>
				<CFSET WriteMax=ListLast(SSDWrite,"|")>
				<CFSET SeriesOut=ListAppend(SeriesOut,"{name: '#tmpLabel# (r)', type: 'boxplot', yAxis: 1, data: []}",Chr(10))>
				<CFSET SSDScript=SSDScript & "Chart1.series[#SeriesIndex#].addPoint([#SSDSpot#,#ReadMin#,#ReadMin#,#ReadAvg#,#ReadMax#,#ReadMax#]);" & Chr(10)>
				<CFSET SeriesIndex=SeriesIndex+1>
				<CFSET SSDSpot=SSDSpot - RMinus>
				<CFSET SeriesOut=ListAppend(SeriesOut,"{name: '#tmpLabel# (w)', type: 'boxplot', yAxis: 1, data: []}",Chr(10))>
				<CFSET SSDScript=SSDScript & "Chart1.series[#SeriesIndex#].addPoint([#SSDSpot#,#WriteMin#,#WriteMin#,#WriteAvg#,#WriteMax#,#WriteMax#]);" & Chr(10)>
				<CFSET SSDSpot=SSDSpot - NMinus>
				<CFSET MaxSSDSpeed=Max(Max(MaxSSDSpeed,ReadMax),WriteMax)>
			<CFELSE>
				<CFSET SeriesIndex=SeriesIndex + 1>
				<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/speed.json" variable="json">
				<CFSET tmp=JSONQuerytoCFQuery(DeserializeJSON(json),"integer,varchar,date,integer,integer")>
				<CFQUERY name="DriveData" dbtype="Query">
					SELECT * FROM tmp ORDER BY Spot
				</CFQUERY>
				<CFIF DriveData.RecordCount GT 0>
					<CFSET SN=DriveID>
					<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ "">
						<CFSET SN=HW[Key].Ports[PortNo].UNRAIDSlot & " (#DriveID#)">
					</CFIF>
					<CFSET Data="">
					<CFLOOP index="speedidx" from="1" to="#DriveData.RecordCount#">
						<CFSET Data=ListAppend(Data,"[" & DriveData.Spot[speedidx] & "," & DriveData.Speed[speedidx] & "]")>
					</CFLOOP>
					<CFSET SeriesOut=ListAppend(SeriesOut,"{name: '#tmpLabel#', type: 'spline', data: [#Data#]}",Chr(10))>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#PersistDir#/driveinfo/DriveBenchmarks.txt" output="#MaxSize#|#SSDsExist#|#MaxSSDSpeed#|#SSDScript#|#SeriesOut#" addnewline="NO" mode="666">
	</cflock>
</CFIF>

<CFIF SeriesOut NEQ "">
	<CFOUTPUT>
	<div id="graph1" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto;"></div>
	<script type="text/javascript">
	var Chart1=Highcharts.chart('graph1', {
		title: {
			text: 'Benchmark Speeds'
		},
		subtitle: {
			text: 'Most recent scan per drive'
		},
<CFIF SSDsExist EQ 0>
		xAxis: {
			title: {
				text: 'Size'
			},
			min: 0,
			max: #MaxSize#
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
			max: #MaxSize#
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
			max: #MaxSSDSpeed#,
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
		series: [
			#Replace(SeriesOut,Chr(10),"," & Chr(10),"ALL")#
		]
	});
	#SSDScript#
	</script>
	</CFOUTPUT>

</CFIF>

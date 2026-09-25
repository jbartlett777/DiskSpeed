<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
	<CFSET HWTree=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/usbtree.json" variable="json">
	<CFSET USBTree=DeserializeJSON(json)>
<CFELSE>
	<CFABORT>
</CFIF>

<CFINCLUDE TEMPLATE="Styles.cfm">
<CFFILE action="read" file="#SaveDir#/drives.css" variable="DriveCSS">
<CFOUTPUT>
<style type="text/css">
#DriveCSS#
</style>
<body>
</CFOUTPUT>

<CFPARAM name="URL.Edit" default="">
<CFPARAM name="URL.ManageBenchmarks" default="">
<CFPARAM name="URL.ClearBenchmarks" default="">
<CFPARAM name="URL.Benchmark" default="">
<CFPARAM name="URL.SubmitDrive" default="">

<CFIF URL.Edit EQ "Y">
	<CFINCLUDE template="EditDrive.cfm">
	<cfexit method="exittemplate">
</CFIF>

<CFSET Key=ListFirst(URL.Drive,"|")>
<CFSET PortNo=ListLast(URL.Drive,"|")>

<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>

<!---
<CFIF URL.ClearBenchmarks EQ "Y" AND FileExists("#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark/allspeed.json")>
	<CFDIRECTORY action="delete" directory="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark" recurse="yes">
	<CFLOCATION url="DispDrive.cfm?Drive=#URLEncodedFormat(URL.Drive)#" addtoken="NO">
</CFIF>
--->

<CFTRY>
	<CFSET HashDir=HW[Key].Ports[PortNo].DriveHash>
<CFCATCH Type="Any">
	<CFLOCATION URL="index.cfm" addtoken="NO">
</CFCATCH>
</CFTRY>
<CFDIRECTORY action="list" directory="#PersistDir#/optimize/#HashDir#" type="file" filter="*.3.txt" name="dir">

<CFSET Speeds=QueryNew("BlockSize,Speed","integer,integer")>
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="read" file="#PersistDir#/optimize/#HashDir#/#Dir.Name[CR]#" variable="Data">
	<CFSET Data=StripCR(Data)>
	<CFSET Speed=ListFirst(ListLast(Data,Chr(10))," ")>
	<CFSET QueryAddRow(Speeds)>
	<CFSET QuerySetCell(Speeds,"BlockSize",ListFirst(Dir.Name[CR],"."))>
	<CFSET QuerySetCell(Speeds,"Speed",Speed)>
</CFLOOP>
<CFQUERY name="speed" dbtype="Query">
	SELECT *
	FROM Speeds
	ORDER BY BlockSize
</CFQUERY>

<CFSET DriveIdent=UNRAIDSlot(HW[Key].Ports[PortNo].UNRAIDSLot)>
<CFIF DriveIdent EQ "">
	<CFSET DriveIdent=HW[Key].Ports[PortNo].DriveID>
<CFELSE>
	<CFSET DriveIdent=DriveIdent & " (" & HW[Key].Ports[PortNo].DriveID & ")">
</CFIF>

<CFIF URL.Benchmark EQ "Y">
	<cfexit method="exittemplate">
</CFIF>

<CFSET IXList="">

<CFSET NoEdit="N">
<CFINCLUDE template="DispDriveInfo.cfm">

<CFIF URL.ManageBenchmarks NEQ "">
	<CFSET BenchmarkDir="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark">
	<CFSET UsedDates="">
	<CFDIRECTORY action="list" directory="#BenchmarkDir#" type="Dir" name="Dir">
	<!--- Update DateLastModified with the benchmark scan date --->
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="read" file="#BenchmarkDir#/#Dir.Name[CR]#/datestamp.txt" variable="ScanDate">
		<CFSET QuerySetCell(Dir,"DateLastModified",ScanDate,CR)>
	</CFLOOP>
	<CFQUERY name="tmp" dbtype="Query">
		SELECT * FROM Dir ORDER BY DateLastModified DESC
	</CFQUERY>
	<CFSET Dir=Duplicate(tmp)>
	<!--- <cfdump var=#dir#> --->

	<CFTRY>
		<CFSET UserIDSHA=LCase(Hash(Hash(Config.var.RegTo,"SHA") & Hash(Config.var.RegGUID,"SHA"),"SHA"))>
		<CFSET SerialHash=LCase(Hash36("#HW[Key].Ports[PortNo].Attrib.Vendor#|#HW[Key].Ports[PortNo].Attrib.Model#|#HW[Key].Ports[PortNo].Attrib.Serial#"))>
		<CFSET H=LCase(Hash(input="#UserIDSHA#|#SerialHash#",algorithm="SHA-512",numIterations = 10))>
		<!--- <cfoutput>
		UserIDSHA: #UserIDSHA#<br>
		SerialHash: #SerialHash#<br>
		H: #H#<br>
		http://192.168.1.27:8888/diskspeed/GetBenchmarks.cfm?U=#UserIDSHA##H#1#SerialHash#
		</cfoutput><cfabort> --->
		<!--- <CFOUTPUT>http://strangejourney.net/diskspeed/GetBenchmarks.cfm?U=#UserIDSHA##H#0#SerialHash#</cfoutput> --->
		<!--- <CFHTTP URL="http://192.168.1.27:8888/diskspeed/GetBenchmarks.cfm?U=#UserIDSHA##H#0#SerialHash#"> --->
		<CFHTTP URL="#StrangeJourney#/diskspeed/GetBenchmarks.cfm?U=#UserIDSHA##H#0#SerialHash#">
		<!--- <cfdump var=#CFHTTP#> --->
		<cfwddx input="#CFHTTP.FileContent#" output="In" action="wddx2cfml">
		<CFSET BenchHist=Duplicate(In.BenchHist)>
		<CFSET BenchHistData=Duplicate(In.BenchData)>
		<CFQUERY name="tmp" dbtype="Query">
			SELECT * FROM BenchHist ORDER BY DateStamp DESC
		</CFQUERY>
		<CFSET BenchHist=Duplicate(tmp)>
		<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
			<CFFILE action="write" file="#BenchmarkDir#/BenchInfo.wddx" output="#CFHTTP.FileContent#" addnewline="NO" mode="666">
		</cflock>
		<!--- <cfdump var=#BenchHist#><cfdump var=#BenchHistData#> --->
	<CFCATCH Type="Any">
		<CFOUTPUT>There was an error fetching the benchmark history.<br>#cfcatch.message#<br><br></CFOUTPUT>
		<CFSET BenchHist=QueryNew("ID","integer")>
	</CFCATCH>
	</CFTRY>

	<CFSET SeriesOut="">
	<CFSET SeriesDateStamps="">
	<CFSET Tags="">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFSET BenchFile=BenchmarkDir & "/" & Dir.Name[CR] & "/speed.json">
		<CFFILE action="read" file="#BenchFile#" variable="json">
		<CFSET BenchData=JSONQuerytoCFQuery(DeserializeJSON(json),"integer,varchar,date,integer,integer")>
		<CFSET Data="">
		<CFLOOP index="speedidx" from="1" to="#BenchData.RecordCount#">
			<CFSET Data=ListAppend(Data,"[" & BenchData.Spot[speedidx] & "," & BenchData.Speed[speedidx] & "]")>
		</CFLOOP>
		<CFSET CurrDateStamp=DateFormat(BenchData.DateStamp[1],"mmm d, yyyy") & " " & TimeFormat(BenchData.DateStamp[1],"h:mm tt")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp," ","_","ALL")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp2,",","","ALL")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp2,":","","ALL")>
		<CFSET UsedDates=ListAppend(UsedDates,CurrDateStamp,"|")>
		<CFSET SeriesDateStamps=ListAppend(SeriesDateStamps,Dir.Name[CR] & "|" & CurrDateStamp,"~")>
		<CFSET SeriesOut=ListAppend(SeriesOut,"{name: '#DateFormat(BenchData.DateStamp[1],"mmm d, yyyy")# #TimeFormat(BenchData.DateStamp[1],"h:mm tt")#', type: 'spline', data: [#Data#]}")>
		<CFSET Tags=Tags & '<input type="hidden" id="import_#CurrDateStamp2#" name="Keep" value="#CurrDateStamp#">'>
	</CFLOOP>

	<CFOUTPUT>
	<form id="ManageBenchmarksForm" action="ManageBenchmarks.cfm" method="POST">
	<input type="Hidden" name="Drive" value="#URL.Drive#">
	<table border="0" cellpadding="0" cellspacing="0" width="800px"><tr><td>
	<div id="graph" style="min-width: 310; max-width: 800px; height: 400px; margin: 0 auto;"></div>
	The default visible benchmarks are saved in your local history. The default hidden benchmarks are from your online submissions.
	Click on the legend entry to make visible the benchmarks you wish to keep.<br><br>
	#Tags#
	<CFLOOP index="CR" from="1" to="#BenchHist.RecordCount#">
		<CFSET CurrDateStamp=DateFormat(BenchHist.DateStamp[CR],"mmm d, yyyy") & " " & TimeFormat(BenchHist.DateStamp[CR],"h:mm tt")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp," ","_","ALL")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp2,",","","ALL")>
		<CFSET CurrDateStamp2=Replace(CurrDateStamp2,":","","ALL")>
		<CFIF ListFindNoCase(UsedDates,CurrDateStamp,"|") EQ 0>
			<CFQUERY name="BenchData" dbtype="Query">
				SELECT *
				FROM BenchHistData
				WHERE BenchMarkID=#BenchHist.ID[CR]#
				ORDER BY Spot
			</CFQUERY>
			<CFSET Data="">
			<CFLOOP index="speedidx" from="1" to="#BenchData.RecordCount#">
				<CFSET Data=ListAppend(Data,"[" & BenchData.Spot[speedidx] & "," & BenchData.Speed[speedidx] & "]")>
			</CFLOOP>
			<CFSET SeriesOut=ListAppend(SeriesOut,"{visible: false, name: '#CurrDateStamp#', type: 'spline', data: [#Data#]}")>
			<CFSET json=SerializeJSON(BenchData)>
			<input type="hidden" id="import_#CurrDateStamp2#" name="import" value="">
		</CFIF>
	</CFLOOP>
	<input type="Button" onClick="document.location='DispDrive.cfm?Drive=#URLEncodedFormat(URL.Drive)#'" value="Cancel">
	<input type="Button" id="submitbutton" onClick="this.disabled=true;document.getElementById('ManageBenchmarksForm').submit();" value="Update Benchmarks">
	</form>
	</td></tr></table>
	<script type="text/javascript">
	var Chart=Highcharts.chart('graph', {
		title: {
			text: ''
		},
		xAxis: {
			title: {
				text: 'Location'
			},
			min: 0,
			max: #HW[Key].Ports[PortNo].Attrib.Size.Bytes#
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
	            animation: false,
	            connectNulls: true,
				events: {
					legendItemClick: function () {
						var id=this.name;
						id=id.replace(/ /g,'_');
						id=id.replace(/,/g,'');
						id=id.replace(/:/g,'');
						//alert(id);
						var visibility = this.visible ? false : true;
						//if (!confirm('The series is currently ' + visibility + '. Do you want to change that?')) {
						//	return false;
						//}
						//alert(document.getElementById('import_' + id));
						//alert(visibility);
						if (visibility == true) {
							document.getElementById('import_' + id).value=this.name;
						} else {
							document.getElementById('import_' + id).value='';
						}
						//document.getElementById('import_' + id).checked=visibility;

						return true;
					}
				}
	        }
	    },
	    tooltip: {
	        formatter: function() {
	        	var outx=Math.round(this.x / 1000000000);
	        	var outy=(this.y / 1000000).toFixed(2);
	            return this.series.name + ': ' + outy + 'MB/sec at ' + outx + 'GB';
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
		series: [#SeriesOut#]
	});
	</script>
	</CFOUTPUT>
	<cfexit method="exittemplate">

<CFELSE>
	<CFSET Benchmarkable=1>
	<CFSET BenchmarkBadReason="">
	<CFSET DriveUUID="FOOBAR">

	<CFOUTPUT>
	<!---<CFIF HW[Key].USB EQ 0>--->
		<CFSET Benchmarkable=0>
		<CFIF Drive.Attrib.Configuration.RPM NEQ "Solid State Device">
			<CFSET Benchmarkable=1>
			<CFIF Benchmarkable EQ 1 AND ListFindNoCase("BD-RE,DVD-ROM",Drive.ATTRIB.Model)>
				<CFSET Benchmarkable=0>
				<CFSET BenchmarkBadReason="NoDisp">
			</CFIF>
		<CFELSE>
			<CFSET MountPointFound=0>
			<CFLOOP index="i" from="1" to="#ArrayLen(Drive.Partitions.Partitions)#">
				<CFIF Drive.Partitions.Partitions[i].MountPoint NEQ "">
					<CFIF DirectoryExists(Drive.Partitions.Partitions[i].MountPoint)>
						<CFSET MountPointFound=1>
						<CFIF StructKeyExists(Drive.Partitions.Partitions[i],"UsedSpace")>
							<CFIF Drive.Partitions.Partitions[i].Size - Drive.Partitions.Partitions[i].UsedSpace GTE OneGB * 5>
								<CFSET Benchmarkable=1>
								<CFSET DriveUUID=Drive.Partitions.Partitions[i].UUID>
								<CFIF Trim(DriveUUID) EQ "">
									<CFSET DriveUUID=Drive.DriveID>
								</CFIF>
								<CFBREAK>
							<CFELSE>
								<CFSET BenchmarkBadReason=ListAppend(BenchmarkBadReason,"Identified mount point " & Drive.Partitions.Partitions[i].MountPoint & " does not have 5GB available space. To benchmark drives with less space available, use the ""Benchmark Buttons"" from the main page.","|")>
							</CFIF>
						<CFELSE>
							<CFSET BenchmarkBadReason=ListAppend(BenchmarkBadReason,"Identified mount point " & Drive.Partitions.Partitions[i].MountPoint & " does not have 5GB available space. To benchmark drives with less space available, use the ""Benchmark Buttons"" from the main page.","|")>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFLOOP>
			<CFIF Benchmarkable EQ 0 AND MountPointFound EQ 0>
				<CFSET BenchmarkBadReason=ListAppend(BenchmarkBadReason,"Docker volume mount not detected","|")>
			</CFIF>

			<CFIF Benchmarkable>
				<!--- Check to see if there are enough CPU's available to Docker --->
				<CFSET Err=CheckDockerCPUCount()>
				<CFIF Err NEQ "">
					<CFSET Benchmarkable=0>
					<CFSET BenchmarkBadReason=ListAppend(BenchmarkBadReason,Err)>
				</CFIF>
			</CFIF>
		</CFIF>

		<table border="0" cellpadding="0" cellspacing="0">
			<tr>
			<CFIF Left(HW[Key].Ports[PortNo].DriveID,2) NEQ "zz">
				<!--- <td valign="top">
					<form action="index.cfm" method="get">
					<input type="Hidden" name="Drive" value="#URL.Drive#">
					<input type="Hidden" name="BenchmarkDrive" value="Y">
					<input type="Submit" value="Benchmark Drive">
					</form>
				</td>
				<td>&nbsp;&nbsp;&nbsp;</td> --->
			</CFIF>
				<td valign="top">
					<form action="EditDrive.cfm" method="get">
					<input type="Hidden" name="Drive" value="#URL.Drive#">
					<input type="Hidden" name="Edit" value="Y">
					<input type="Submit" value="Edit Drive">
					</form>
				</td>
				<CFIF Left(HW[Key].Ports[PortNo].DriveID,2) NEQ "zz">
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<CFIF Benchmarkable>
							<form action="Benchmark.cfm" method="POST" target="_parent">
							<input type="Hidden" name="Seconds" value="30">
							<input type="Hidden" name="Per" value="10">
							<input type="Hidden" name="Drives" value="#HW[Key].Ports[PortNo].DriveID#">
							<input type="Hidden" name="DisableSpeedGap" value="1">
							<input type="Hidden" name="go" value="Start Drive Benchmarks">
							<input type="Submit" value="Benchmark Drive">
							</form>
							<CFIF DockerInfo.CPU.Assigned EQ 4 AND IsNumeric(Drive.Attrib.Configuration.RPM) EQ "NO">
								<span class="Red">
								<br>
								<small>
								WARNING: You have only 4 CPUs available to the DiskSpeed Docker app. The Solid State benchmarks splits up the write tasks over 4
								threads, please be sure no other process is running to get an accurate benchmark.
								<CFIF DockerInfo.CPU.Total GT 4>
									Idealy, assign 5+ CPUs to DiskSpeed.<br>
								</CFIF>
								</small>
								</span>
							</CFIF>
						<CFELSE>
							<CFIF BenchmarkBadReason NEQ "NoDisp">
								Unable to benchmark for the following reason<CFIF ListLen(BenchmarkBadReason,"|") NEQ 1>s</CFIF><br>
								* #Replace(BenchmarkBadReason,"|","* ","ALL")#<br>
								You will need to restart the DiskSpeed docker after making changes to mounted drives for changes to take effect.<br>
								For more information how the benchmarks work, view the <span class="Size14 Red Hand Underline" data-fancybox data-type="iframe" data-src="/BenchmarkHelp.cfm?x=#GetTickCount()#">FAQ</span>
							</CFIF>
						</CFIF>
					</td>
				</CFIF>
				<CFIF HW[Key].Ports[PortNo].Config.DriveEdited EQ 1 AND URL.SubmitDrive NEQ "Yes">
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<form action="DispDrive.cfm" method="get">
						<input type="Hidden" name="Drive" value="#URL.Drive#">
						<input type="Hidden" name="SubmitDrive" value="Y<CFIF URL.SubmitDrive EQ "Y">es</CFIF>">
						<input type="Submit" value="Submit Drive">
						</form>
					</td>
				</CFIF>
				<CFIF FileExists("#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark/allspeed.json")>
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<form action="DispDrive.cfm" method="get">
						<input type="Hidden" name="Drive" value="#URL.Drive#">
						<input type="Hidden" name="ManageBenchmarks" value="Y">
						<input type="Submit" value="Manage Benchmarks">
						</form>
					</td>
				</CFIF>
				<!--- <CFIF Left(HW[Key].Ports[PortNo].DriveID,2) NEQ "zz" AND HW[Key].Ports[PortNo].Attrib.Configuration.RPM NEQ "Solid State Device"> --->
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<form action="SurfaceScan.cfm" method="GET" target="_top">
						<input type="Hidden" name="Drive" value="#HW[Key].Ports[PortNo].DriveID#">
						<!-- <input type="Submit" value="Surface Scan Heat Map"> -->
						</form>
					</td>
				<!--- </CFIF> --->
			</tr>
		</table>
	<!---</CFIF>--->
	<CFIF URL.SubmitDrive EQ "Y">
		<br>
		<span class="Red">
		You are about to submit your drive configuration for the #HW[Key].Ports[PortNo].Attrib.Vendor# #HW[Key].Ports[PortNo].Attrib.Size.DispSize#
		drive, model #HW[Key].Ports[PortNo].Attrib.Model#, to the Central Repository. Information sent will be the drive image and text settings.<br>
		<br>
		Note: If you previously sent an update for this drive, this will overwrite it.<br>
		</span>
		<br>
		Press "Submit Drive" again to confirm.
	</CFIF>
	</CFOUTPUT>
</CFIF>

<CFIF URL.SubmitDrive EQ "Yes">
	<CFINCLUDE TEMPLATE="SubmitDrive.cfm">
</CFIF>

<!--- Display SSD Benchmark Graph --->
<CFIF Drive.Attrib.Configuration.RPM EQ "Solid State Device">
	<!--- Restore SSD Benchmark tests --->
	<CFSET BenchmarksDir="#PersistDir#/driveinfo/#Drive.Config.SaveDir#/benchmark">
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
			<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/SSDReadSpeedList.txt" variable="ReadSpeedList">
			<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/SSDWriteSpeedList.txt" variable="WriteSpeedList">
			<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/SSDTestFileSize.txt" variable="TestFileSize">
			<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/SSDReadSpeed.txt" variable="ReadSpeeds">
			<CFFILE action="read" file="#BenchmarksDir#/#UseBenchDir#/SSDWriteSpeed.txt" variable="WriteSpeeds">
			<CFSET BouncyFile=ReadFile("#BenchmarksDir#/#UseBenchDir#/BouncyDrive.txt","0")>
			<CFSET AvgRead=ListFirst(ReadSpeeds,"|")>
			<CFSET MinRead=ListGetAt(ReadSpeeds,2,"|")>
			<CFSET MaxRead=ListGetAt(ReadSpeeds,3,"|")>
			<CFSET AvgWrite=ListFirst(WriteSpeeds,"|")>
			<CFSET MinWrite=ListGetAt(WriteSpeeds,2,"|")>
			<CFSET MaxWrite=ListGetAt(WriteSpeeds,3,"|")>
			<CFSET SubTitle="Each bar represents one #KBytes(TestFileSize)# test file.">
			<!---
			<CFSET SubTitle=SubTitle & "Read: " & ListFirst(KBytes(MinRead)," ") & " - " & KBytes(MaxRead) & "/Sec, " & KBytes(AvgRead) & "/Sec Avg<br>">
			<CFIF BouncyFile EQ 1>
				<CFSET SubTitle=SubTitle & "Write: " & ListFirst(KBytes(MinWrite)," ") & " - " & KBytes(MaxWrite) & "/Sec, " & KBytes(AvgWrite) & "/Sec Avg">
			<CFELSE>
				<CFSET SusWrite=ListGetAt(WriteSpeeds,4,"|")>
				<CFSET SubTitle=SubTitle & "Burst Write: " & ListFirst(KBytes(MinWrite)," ") & " - " & KBytes(MaxWrite) & "/Sec, " & KBytes(AvgWrite) & "/Sec Avg.<br>">
				<CFSET SubTitle=SubTitle & "Sustained Write: " & KBytes(SusWrite) & "/Sec">
			</CFIF>
			--->

			<CFOUTPUT>
			<div id="container"></div>
			<script language="Javascript">
			function MByte(i) {
				if (i <= 1000) return String(i) + ' MB/Sec';
				i=parseInt(i / 1000, 10);
				if (i <= 1000) return String(i) + ' GB/Sec';
				i=parseInt(i / 1000, 10);
				return String(i) + ' TB/Sec';
			}
			Highcharts.chart('container', {
				chart: {
					type: 'column'
				},
				title: {
					text: 'SSD Read/Write Speeds'
				},
				subtitle: {
					text: '#SubTitle#'
				},
				xAxis: {
					categories: ['Read Speed','Write Speed',''],
					title: {
					text: null
				}
				},
				yAxis: {
					min: 0,
					title: {
					text: null
				},
				plotLines: [{
					value: #AvgRead#,
					color: 'green',
					width: 1,
					label: {
						text: 'Avg Read Speed (#KBytes(AvgRead,"9,999.9")#/sec)',
					align: 'right',
					style: {
						color: 'gray'
					}
				}
				},{
					value: #AvgWrite#,
					color: 'red',
					width: 1,
					label: {
						text: 'Avg Write Speed (#KBytes(AvgWrite,"9,999.9")#/sec)',
						align: 'right',
						style: {
							color: 'gray'
						}
					}
				}]
				},
				plotOptions: {
					column: {
						dataLabels: {
							enabled: false
						},
						states: {
							hover: {
								enabled: false
							},
							select: {
								enabled: false
							}
						}
					}
				},
				credits: {
					enabled: false
				},
				legend: {
					enabled: false
				},
				tooltip: {
					hideDelay: 500,
					headerFormat: '',
					formatter: function() {
						return '<span style="color: black; font-weight: bold;">' + (this.y / 1000000).toFixed(1) + ' MB/Sec</span><br/>'
					}
				},
				series: [
				<CFLOOP index="i" from="1" to="#ListLen(ReadSpeedList)#">
					{
						name: 'Pass 1',
						color: '##318cec',
						data: [#ListGetAt(ReadSpeedList,i)#,#ListGetAt(WriteSpeedList,i)#,0]
					}
					<CFIF i LT ListLen(ReadSpeedList)>,</CFIF>
				</CFLOOP>
				]
			});
			</script>
			</CFOUTPUT>
		</CFIF>
	</CFIF>
</CFIF>

<!--- Display heat map --->
<CFSET HeatDir="#PersistDir#/driveinfo/#Drive.Config.SaveDir#/surfacescan">
<CFIF FileExists("#HeatDir#/Heatmap_#Drive.OptimalBlockSize#.json")>
	<CFSET NoHeader=1>
	<CFFILE action="read" file="#HeatDir#/Heatmap_#Drive.OptimalBlockSize#.json" variable="HeatMapJSON">
	<CFSET MinSpeed=0>
	<CFSET MaxSpeed=0>
	<CFIF FileExists("#HeatDir#/MinSpeed.txt")>
		<CFFILE action="read" file="#HeatDir#/MinSpeed.txt" variable="MinSpeed">
	</CFIF>
	<CFIF FileExists("#HeatDir#/MaxSpeed.txt")>
		<CFFILE action="read" file="#HeatDir#/MaxSpeed.txt" variable="MaxSpeed">
	</CFIF>
	<CFINCLUDE template="DispHeatmap.cfm">
</CFIF>


<CFIF FileExists("#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark/allspeed.json")>
	<CFFILE action="read" file="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark/allspeed.json" variable="allspeedjson">
	<CFFILE action="read" file="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark/avgspeed.json" variable="avgspeedjson">
	<CFSET allspeed=DeserializeJSON(allspeedjson,false)>
	<CFSET avgspeed=DeserializeJSON(avgspeedjson,false)>

	<CFSET QueryAddColumn(AllSpeed,"DateStamp2","time")>
	<CFLOOP index="dateidx" from="1" to="#AllSpeed.RecordCount#">
		<CFSET QuerySetCell(AllSpeed,"DateStamp2",CreateODBCDateTime(AllSpeed.DateStamp[dateidx]),dateidx)>
	</CFLOOP>
	<CFQUERY name="tmp" dbtype="Query">
		SELECT Drive, DateStamp2 AS DateStamp, Spot, Speed
		FROM AllSpeed
	</CFQUERY>
	<CFSET AllSpeed=Duplicate(tmp)>

	<CFSET SeriesOut="">
	<CFQUERY name="TestDates" dbtype="Query">
		SELECT DISTINCT DateStamp
		FROM AllSpeed
		ORDER BY DateStamp DESC
	</CFQUERY>

	<CFLOOP index="dateidx" from="1" to="#TestDates.RecordCount#">
		<CFQUERY name="TestData" dbtype="Query">
			SELECT *
			FROM AllSpeed
			WHERE DateStamp=#CreateODBCDateTime(TestDates.DateStamp[dateidx])#
			ORDER BY Spot
		</CFQUERY>
		<CFSET Data="">
		<CFLOOP index="speedidx" from="1" to="#TestData.RecordCount#">
			<CFSET Data=ListAppend(Data,"[" & TestData.Spot[speedidx] & "," & TestData.Speed[speedidx] & "]")>
		</CFLOOP>
		<CFSET SeriesOut=ListAppend(SeriesOut,"{name: '#DateFormat(TestDates.DateStamp[dateidx],"mmm d, yyyy")# #TimeFormat(TestDates.DateStamp[dateidx],"h:mm tt")#', type: 'spline', data: [#Data#]}")>
	</CFLOOP>
	<!---
	<CFSET Data="">
	<CFLOOP index="speedidx" from="1" to="#AvgSpeed.RecordCount#">
		<CFSET Data=ListAppend(Data,"[" & AvgSpeed.Spot[speedidx] & "," & AvgSpeed.AvgSpeed[speedidx] & "]")>
	</CFLOOP>
	<CFIF TestDates.RecordCount GT 1>
		<CFSET SeriesOut=ListAppend(SeriesOut,"{name: 'Average', type: 'spline', data: [#Data#]}")>
	</CFIF>
	--->

	<CFOUTPUT>
	<div id="graph1" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto;"></div>
	<script type="text/javascript">
	var Chart1=Highcharts.chart('graph1', {
		title: {
			text: 'Benchmark Speeds'
		},
		xAxis: {
			title: {
				text: 'Size'
			},
			min: 0,
			max: #HW[Key].Ports[PortNo].Attrib.Size.Bytes#
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
	            animation: false,
	            connectNulls: true
	        }
	    },
	    tooltip: {
	        formatter: function() {
	        	var outx=Math.round(this.x / 1000000000);
	        	var outy=(this.y / 1000000).toFixed(2);
	            return this.series.name + ': ' + outy + 'MB/sec at ' + outx + 'GB';
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
		series: [#SeriesOut#]
	});
	</script>
	</CFOUTPUT>

</CFIF>
<!--- <cfdump var=#config#>
		<CFDUMP var=#hw#>
		<cfdump var=#ref#> --->

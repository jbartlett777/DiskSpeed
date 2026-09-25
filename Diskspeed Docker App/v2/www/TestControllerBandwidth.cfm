<cfsetting enablecfoutputonly="true" requesttimeout="9999">

<CFSET TestSec=15>

<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET SessionID=Session.RequestID>
</cflock>

<CFINCLUDE TEMPLATE="SetKillFlag.cfm">

<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
<CFELSE>
	<CFLOCATION URL="ScanControllers.cfm" AddToken="NO">
</CFIF>

<!---
<CFPARAM name="FORM.MaxDrives" default="">
<CFIF IsNumeric(FORM.MaxDrives)>
	<CFSET HW[FORM.Controller].MaxReadDrives=FORM.MaxDrives>
	<CFSET HW[FORM.Controller].ControllerOptimized=1>
	<CFSET json=SerializeJSON(HW)>
	<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
	<CFLOCATION URL="index.cfm?controller=#URLEncodedFormat(FORM.Controller)#" addtoken="NO">
</CFIF>
--->

<CFSET Key=URL.Controller>
<CFIF StructKeyExists(HW,Key) EQ "NO">
	<CFLOCATION URL="index.cfm" addtoken="NO">
</CFIF>
<CFSET SaveKey=Replace(Key,":","_","ALL")>
<CFSET SaveKey=Replace(Key,".","_","ALL")>

<CFSET WakeupDrives="">
<CFSET BWDir="#PersistDir#/controller/bandwidth/" & HW[Key].BandwidthHash>
<CFIF DirectoryExists(BWDir) EQ "NO">
	<CFDIRECTORY action="Create" directory="#BWDir#" createpath="true" mode="666">
</CFIF>

<CFINCLUDE TEMPLATE="KillDiskPIDs.cfm">

<CFSET DriveList="">
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
	<CFIF DriveID NEQ "">
		<CFIF HW[Key].Ports[PortNo].UNRAIDSlot EQ "Parity">
			<CFSET DriveList=ListAppend(DriveList,DriveID)>
			<CFBREAK>
		</CFIF>
	</CFIF>
</CFLOOP>
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
	<CFIF DriveID NEQ "">
		<CFIF HW[Key].Ports[PortNo].UNRAIDSlot EQ "Parity 2">
			<CFSET DriveList=ListAppend(DriveList,DriveID)>
			<CFBREAK>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFLOOP index="i" from="1" to="50">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].UNRAIDSlot EQ "Disk #i#">
				<CFSET DriveList=ListAppend(DriveList,DriveID)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
	<CFIF DriveID NEQ "">
		<CFIF HW[Key].Ports[PortNo].UNRAIDSlot EQ "Cache">
			<CFSET DriveList=ListAppend(DriveList,DriveID)>
			<CFBREAK>
		</CFIF>
	</CFIF>
</CFLOOP>
<CFLOOP index="i" from="2" to="50">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
		<CFIF DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].UNRAIDSlot EQ "Cache #i#">
				<CFSET DriveList=ListAppend(DriveList,DriveID)>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<!--- Catch any unassigned drives --->
<CFSET UnassignedDrives="">
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
	<CFIF DriveID NEQ "">
		<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
			<CFIF ListFindNoCase(DriveList,DriveID) EQ 0>
				<CFSET UnassignedDrives=ListAppend(UnassignedDrives,DriveID)>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFIF UnassignedDrives NEQ "">
	<CFSET UnassignedDrives=ListSort(UnassignedDrives,"text")>
	<CFSET DriveList=ListAppend(DriveList,UnassignedDrives)>
</CFIF>

<CFSET Data=StructNew()>
<CFSET MaxGap=0>

<CFOUTPUT>
<div id="Benchmarks">
</CFOUTPUT>
<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFINCLUDE TEMPLATE="CheckForKillFlag.cfm">

	<!--- Check to see if we've benchmarked this drive in the past. If so, get the average speed at the start of the drive --->
	<CFSET Key=Ref.DriveID[CurrDrive].Key>
	<CFSET PortNo=Ref.DriveID[CurrDrive].PortNo>
	<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
	<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
		<CFSET AvgSpeedJSON=PersistDir & "/driveinfo/" & Drive.Config.SaveDir & "/benchmark/avgspeed.jsonxxxx"> <!--- forcing drive match logic to not file one --->

		<CFIF FileExists(AvgSpeedJSON)>
			<CFFILE action="read" file="#AvgSpeedJSON#" variable="JSON">
			<CFSET AvgSpeed=DeserializeJSON(JSON,false)>
			<CFQUERY name="CheckSpeed" dbtype="Query">
				SELECT AvgSpeed FROM AvgSpeed WHERE Spot=0
			</CFQUERY>
			<CFSET Data[CurrDrive].Baseline=CheckSpeed.AvgSpeed>
		<CFELSE>
			<CFSET DriveID=Drive.DriveID>
			<CFSET BS=Drive.OptimalBlockSize>
			<CFSET DriveBytes=Drive.Attrib.Size.Bytes>
			<CFSET BlockCount=Int(DriveBytes / BS)>
			<CFSET ResultsFN=BWDir & "/controller_benchmark_single_#DriveID#.txt">
			<CFIF FileExists(ResultsFN)>
				<CFFILE action="DELETE" file="#ResultsFN#">
			</CFIF>
			<CFIF Drive.UNRAIDSlot EQ "">
				<CFSET Label=DriveID>
			<CFELSE>
				<CFSET Label=Drive.UNRAIDSLot & " (#DriveID#)">
			</CFIF>
			<CFOUTPUT>
			Benchmarking #Label#:&nbsp;<progress id="Drive_#DriveID#" value="0" max="15"></progress>
			<script language="JavaScript">
			var timeleft = 16;
			var downloadTimer = setInterval(function(){
				document.getElementById('Drive_#DriveID#').value = 16 - timeleft;
				timeleft -= 1;
				if(timeleft <= 0)
					clearInterval(downloadTimer);
			}, 1000);
			</script>
			</CFOUTPUT><CFFLUSH>
			<CFSET cmd="dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=0 iflag=direct status=progress conv=noerror 2> #ResultsFN# &" & Chr(10) &
					"PID=$!" & Chr(10) &
					"echo 0 > #SaveDir#/pids/$PID" & Chr(10) &
					"sleep #TestSec+1#" & Chr(10) &
					"kill $PID" & Chr(10) &
					"rm #SaveDir#/pids/$PID" & Chr(10) &
					"sleep 1" & Chr(10) &
					"chmod 666 #ResultsFN#" & Chr(10)>
			<CFFILE action="write" file="#BWDir#/#DriveID#_benchmark.sh" mode="766" output="#cmd#" addnewline="NO">
			<CFEXECUTE name="#BWDir#/#DriveID#_benchmark.sh" timeout="3060" />
			<CFSET Result=GetReadAvg(ResultsFN,Drive.Attrib.Configuration.RPM,2,MaxGap)>
			<CFSET Avg=ListFirst(Result,"|")>
			<CFSET Max=ListLast(Result,"|")>
			<CFSET Data[CurrDrive].Baseline=Val(Avg)>
			<CFSET Data[CurrDrive].Max=Val(Max)>
			<CFOUTPUT>
			#KBytes(Avg)#/Sec<br>
			<!--- <pre>#cmd#</pre> --->
			<script language="JavaScript">document.getElementById('Drive_#DriveID#').style.display='none';</script>
			</CFOUTPUT>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFINCLUDE TEMPLATE="CheckForKillFlag.cfm">

<CFOUTPUT>
Performing controller benchmark by reading all attached drives at once for 15 seconds<br>
<progress id="Benchmark" value="0" max="15"></progress>
</CFOUTPUT>

<CFSET cmd="">
<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFSET Key=Ref.DriveID[CurrDrive].Key>
	<CFSET PortNo=Ref.DriveID[CurrDrive].PortNo>
	<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
	<CFSET DriveID=Drive.DriveID>
	<CFSET BS=Drive.OptimalBlockSize>
	<CFSET DriveBytes=Drive.Attrib.Size.Bytes>
	<CFSET BlockCount=Int(DriveBytes / BS)>
	<CFSET ResultsFN=BWDir & "/controller_benchmark_all_#DriveID#.txt">
	<CFIF FileExists(ResultsFN)>
		<CFFILE action="DELETE" file="#ResultsFN#">
	</CFIF>
	<CFSET cmd=cmd & "dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=0 iflag=direct status=progress conv=noerror 2> #ResultsFN# &" & Chr(10) &
					 "PID#DriveID#=$!" & Chr(10) &
					 "echo 0 > #SaveDir#/pids/$PID#DriveID#" & Chr(10)>
</CFLOOP>
<CFSET cmd=cmd & "sleep 16" & Chr(10)>
<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFSET Key=Ref.DriveID[CurrDrive].Key>
	<CFSET PortNo=Ref.DriveID[CurrDrive].PortNo>
	<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
	<CFSET DriveID=Drive.DriveID>
	<CFSET ResultsFN=BWDir & "/controller_benchmark_all_#DriveID#.txt">
	<CFSET cmd=cmd & "kill $PID#DriveID#" & Chr(10) &
					 "rm #SaveDir#/pids/$PID#DriveID#" & Chr(10) &
					 "chmod 666 #ResultsFN#" & Chr(10)>
</CFLOOP>


<CFLOOP index="q" from="1" to="#i#">
</CFLOOP>
<CFSET cmd=cmd & "sleep 1" & Chr(10)>
<CFSET ExecFile="#SaveDir#/" & GetTickCount() & ".sh">
<CFFILE action="write" file="#ExecFile#" mode="766" output="#cmd#" addnewline="NO">

<CFOUTPUT>
<!--- <pre>#cmd#</pre> --->
<script language="JavaScript">
var timeleft = 16;
var downloadTimer = setInterval(function(){
	document.getElementById('Benchmark').value = 16 - timeleft;
	timeleft -= 1;
	if(timeleft <= 0)
		clearInterval(downloadTimer);
}, 1000);
</script>
</CFOUTPUT>
<CFFLUSH>

<CFEXECUTE name="#ExecFile#" timeout="3060" />

<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFSET Key=Ref.DriveID[CurrDrive].Key>
	<CFSET PortNo=Ref.DriveID[CurrDrive].PortNo>
	<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
	<CFSET DriveID=Drive.DriveID>
	<CFSET ResultsFN=BWDir & "/controller_benchmark_all_#DriveID#.txt">
	<CFSET Result=GetReadAvg(ResultsFN,Drive.Attrib.Configuration.RPM,2,MaxGap)>
	<CFSET Avg=Val(ListFirst(Result,"|"))>
	<CFSET Max=Val(ListLast(Result,"|"))>
	<CFSET Data[CurrDrive].Benchmark=Avg>
	<CFSET Data[CurrDrive].BenchmarkMax=Max>
</CFLOOP>

<CFOUTPUT>
</div>
<script language="JavaScript">document.getElementById('Benchmarks').style.display='none';</script>
</CFOUTPUT>

<CFINCLUDE TEMPLATE="CheckForKillFlag.cfm">

<CFSET SingleDrive="">
<CFSET AllDrives="">
<CFSET PercentDiff=0>
<CFSET AllMax=0>
<CFSET SlowSingleDrive=0>
<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFSET SingleDrive=ListAppend(SingleDrive,"{y:#Data[CurrDrive].Baseline#,t:'#KBytes(Data[CurrDrive].Baseline)#/Sec'}")>
	<CFSET AllDrives=ListAppend(AllDrives,"{y:#Data[CurrDrive].Benchmark#,t:'#KBytes(Data[CurrDrive].Benchmark)#/Sec'}")>
	<CFSET AllMax=AllMax + Data[CurrDrive].BenchmarkMax>
	<CFIF Data[CurrDrive].Baseline GTE Data[CurrDrive].Benchmark>
		<CFSET PercentDiff=PercentDiff + 100 - Data[CurrDrive].Benchmark / Data[CurrDrive].Baseline / 0.01>
	<CFELSE>
		<CFSET TmpDiff=100 - Data[CurrDrive].Baseline / Data[CurrDrive].Benchmark / 0.01>
		<!--- <CFSET PercentDiff=PercentDiff + TmpDiff> --->
		<CFIF TmpDiff GT 10>
			<CFSET SlowSingleDrive=SlowSingleDrive + 1>
		</CFIF>
	</CFIF>
</CFLOOP>
<CFSET PercentDiff=PercentDiff / ListLen(DriveList)>

<CFSET Categories="">
<CFLOOP index="CurrDrive" list="#DriveList#">
	<CFSET Key=Ref.DriveID[CurrDrive].Key>
	<CFSET PortNo=Ref.DriveID[CurrDrive].PortNo>
	<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
	<CFIF Drive.UNRAIDSlot EQ "">
		<CFSET Categories=ListAppend(Categories,CurrDrive)>
	<CFELSE>
		<CFSET Categories=ListAppend(Categories,Drive.UNRAIDSlot)>
	</CFIF>
</CFLOOP>

<CFSET GraphHeight=150 + 60 * ListLen(DriveList)>

<CFSAVECONTENT variable="BenchmarkHTML">
<CFOUTPUT>
<div id="Controller_#SaveKey#" style="width:800px;min-width:310px;height:#GraphHeight#px;margin:0 auto;float:left;"></div>
<script language="Javascript">
Graph=Highcharts.chart('Controller_#SaveKey#', {
  "title": {
    "text": "Controller Benchmark"
  },
  "subtitle": {
    "text": ""
  },
  "exporting": {},
  "chart": {
    "inverted": true,
    "polar": false
  },
    plotOptions: {
        series: {
        	groupPadding: 0.1,
            dataLabels: {
                enabled: true,
                formatter:function() {
                    return this.point.t;
                }
            }
        }
    },
  "xAxis": {
    "index": 0,
    "isX": true,
    categories: ['#Replace(Categories,",","','","ALL")#'],
	title: {
            text: null
        }
  },
  "yAxis": {
    index: 0,
	title: {
            text: 'Simultaneous max throughput: #KBytes(AllMax)#/Sec'
        }
  },
  "series": [
    {
      "turboThreshold": 0,
      "type": "column",
      "dashStyle": "Solid",
      "name": "Single Drive Avg Speed",
      "enableMouseTracking": false,
      "grouping": true,
      "stickyTracking": true,
      "visible": true,
      animation: false,
      "marker": {},
      data:[#SingleDrive#]
    },
    {
      "turboThreshold": 0,
      "type": "column",
      "name": "Avg speed with All Drives Active",
      "displayNegative": true,
      animation: false,
      "enableMouseTracking": false,
      data:[#AllDrives#]
    }
  ],
  "lang": {
    "thousandsSep": ","
  },
  "credits": {
    "enabled": false
  },
  "pane": {
    "background": []
  },
  "responsive": {
    "rules": []
  },
  "tooltip": {
    "enabled": false
  },
  "annotations": []
});
</script>
<div class="BR"/>
<br>
<CFIF SlowSingleDrive GT 0>
	#SlowSingleDrive# drive<CFIF SlowSingleDrive GT 1>s</CFIF> reported a significantly slower single drive speed than all the drives reading at the same time.
	This is an abnormal test result. Please re-run this benchmark. If this result occurs again, restart the DiskSpeed docker app and try again.
<CFELSE>
	Slight variations between runs and minor improvements in all drives being read at once vs a single drive is normal.<br>
	The average difference between the single drive and all drive read speeds is #NumberFormat(PercentDiff,"999.9")#%<br>
	<CFIF PercentDiff LTE 5>
		Your controller is not bottle-necking.
	<CFELSE>
		The maximum data output of all the drives exceeds the capacity of the drive controller.
	</CFIF>
</CFIF>
</CFOUTPUT>
<br>
</CFSAVECONTENT>

<CFFILE action="write" file="#BWDir#/benchmark.html" output="#BenchmarkHTML#" addnewline="NO" mode="666">

<CFOUTPUT>
#BenchmarkHTML#
</CFOUTPUT>

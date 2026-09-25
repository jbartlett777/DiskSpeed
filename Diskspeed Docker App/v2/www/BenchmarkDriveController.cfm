<cfsetting enablecfoutputonly="true" requesttimeout="7200">
<!--- https://www.mankier.com/1/fio --->

<CFTRY>

<CFPARAM name="URL.Controller" default="">
<CFPARAM name="URL.Drives" default="">
<CFPARAM name="URL.Per" default="">
<CFPARAM name="URL.ScanID" default="">
<CFPARAM name="URL.Seconds" default="">
<CFPARAM name="URL.DisableSpeedGap" default="">
<CFPARAM name="URL.SSDBenchmarkTestFiles" default="#SSDBenchmarkTestFiles_Default#">
<CFPARAM name="URL.MinSSDSpaceFree" default="2147483648">
<CFPARAM name="URL.TestFileSizeOverride" default="0">
<CFPARAM name="URL.SSDSpot" default="0">
<CFPARAM name="URL.SSDBenchmarkCPUs" default="4">
<CFPARAM name="URL.WaitBeforeRead" default="10">

<cfscript>
if (IsNumeric(URL.MinSSDSpaceFree) EQ "NO") URL.MinSSDSpaceFree=2147483648;
if (IsNumeric(URL.TestFileSizeOverride) EQ "NO") URL.TestFileSizeOverride=0;
if (IsNumeric(URL.SSDSpot) EQ "NO") URL.SSDSpot=0;
if (IsNumeric(URL.SSDBenchmarkCPUs) EQ "NO") URL.SSDBenchmarkCPUs=4;
if (IsNumeric(URL.WaitBeforeRead) EQ "NO") URL.WaitBeforeRead=10;
</cfscript>

<CFSAVECONTENT variable="FIO">
<CFOUTPUT>[global]
loops=1
size=[size]
numjobs=1
per_job_logs=1
nrfiles=1
fsync_on_close=0
runtime=60
disk_util=1
ramp_time=1
direct=1
buffered=0
blocksize=128k
zero_buffers
ioengine=libaio
continue_on_error=all
pre_read=0
overwrite=1
directory=[dir]

[DiskSpeedTestFile_[jobid]]
readwrite=[readwrite]
</CFOUTPUT>
</CFSAVECONTENT>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
</CFOUTPUT>

<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET SessionID=Session.RequestID>
</cflock>

<CFSET NMinus=Int(URL.MaxBytes * 0.10)> <!--- minus 10% X per SSD --->
<CFSET RMinus=Int(URL.MaxBytes * 0.01)> <!--- minus 2% X for read from write --->
<CFSET CurrSSDSpot=URL.MaxBytes - (URL.SSDSpot * NMinus)> <!--- SSDSpot is the first X location of the first SSD to benchmark --->

<cflock name="CreateFile" type="exclusive" throwontimeout="false" timeout="5">
	<CFIF FileExists("/tmp/DiskSpeedTmp/benchdone.txt") EQ "NO">
		<CFFILE action="write" file="/tmp/DiskSpeedTmp/benchdone.txt" output="" addnewline="NO" mode="666">
	</CFIF>
</cflock>

<CFIF FileExists("#PersistDir#/storage.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
<CFELSE>
	<CFABORT>
</CFIF>

<!--- Build a list of RAID/pool members --->
<CFSET PoolMembers="">
<CFIF StructKeyExists(Ref,"RAID")>
	<CFIF StructKeyExists(Ref.RAID,"UUID")>
		<CFLOOP index="CurrUUID" list="#StructKeyList(Ref.RAID.UUID)#">
			<CFSET PoolMembers=ListAppend(PoolMembers,Ref.RAID.UUID[CurrUUID])>
		</CFLOOP>
	</CFIF>
</CFIF>

<CFIF Val(URL.SSDBenchmarkTestFiles) LT 1 OR Val(URL.SSDBenchmarkTestFiles) GT 50>
	<CFSET URL.SSDBenchmarkTestFiles=SSDBenchmarkTestFiles_Default>
</CFIF>
<CFIF Val(URL.MinSSDSpaceFree) / OneGB NEQ Int(Val(URL.MinSSDSpaceFree) / OneGB) OR Val(URL.MinSSDSpaceFree) EQ 0>
	<CFSET URL.MinSSDSpaceFree=OneGB * 5>
</CFIF>
<CFSET MinFreeSpaceAvailable=URL.MinSSDSpaceFree>

<CFIF URL.Controller EQ "" OR URL.Drives EQ "">
	<CFABORT>
</CFIF>

<CFSET Variables.SSDBenchmarkTestFiles=URL.SSDBenchmarkTestFiles>

<CFSET BenchmarkFlagFN="/tmp/DiskSpeedTmp/benchmark_" & Replace(URL.Controller,":","_","ALL") & ".txt">
<CFFILE action="write" file="#BenchmarkFlagFN#" output="" addnewline="NO" mode="666">

<CFSET ContName=JSStringFormat(HW[URL.Controller].Config.Product)>
<CFSET ControllerID="controller_" & Replace(Replace(URL.Controller,":","_","ALL"),".","_","All")>

<CFSET Key=URL.Controller>
<CFSET TotalSSD=0> <!--- Used to determine if it's okay to flag the next SSD controller to run --->
<CFSET ScannedSSD=0>
<CFSET PortNoList="">
<CFSET PortNoList1=""> <!--- Holds Port No's with SSD's, used to run first --->
<CFSET PortNoList2=""> <!--- Holds Port No's with hard drvies, used to run after SSD's --->
<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
		<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.RPM EQ "Solid State Device" AND ListFindNoCase(URL.Drives,HW[Key].Ports[PortNo].DriveID)>
			<CFSET TotalSSD=TotalSSD + 1>
			<CFSET PortNoList1=ListAppend(PortNoList1,PortNo)>
		<CFELSE>
			<CFSET PortNoList2=ListAppend(PortNoList2,PortNo)>
		</CFIF>
	</CFIF>
</CFLOOP>
<cfscript>
if (PortNoList1 NEQ "" AND PortNoList2 NEQ "") PortNoList="#PortNoList1#,#PortNoList2#";
if (PortNoList1 NEQ "" AND PortNoList2 EQ "") PortNoList=PortNoList1;
if (PortNoList1 EQ "" AND PortNoList2 NEQ "") PortNoList=PortNoList2;
</cfscript>

<CFLOOP index="PortNo" list="#PortNoList#">
	<CFSET DriveID=HW[Key].Ports[PortNo].DriveID>
	<CFIF ListFindNoCase(URL.Drives,DriveID) AND Left(DriveID,2) NEQ "sr">
		<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>

		<CFLOOP index="CheckSlot" list="#URL.Slots#">
			<CFIF ListFirst(CheckSlot,"-") EQ DriveID>
				<CFSET ChartSlot=ListLast(CheckSlot,"-")>
				<CFBREAK>
			</CFIF>
		</CFLOOP>

		<CFOUTPUT>
		<script>
		parent.document.getElementById('Progress_#ControllerID#_td').style.display='none';
		</script>
		</CFOUTPUT>
		<CFIF Left(DriveID,4) NEQ "nvme" AND HW[Key].Ports[PortNo].Attrib.Configuration.RPM NEQ "Solid State Device">
			<CFOUTPUT>
			#TS()# Spinning up #DriveID# (#HW[Key].Ports[PortNo].Attrib.Size.DispSize#)<br>
			<script language="JavaScript">
			parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Spinning up drive...';
			parent.document.getElementById('Speed_#ControllerID#').innerHTML='';
			</script>
			</CFOUTPUT>
			<CFFLUSH>

			<CFSET WakeupDrives=DriveID>
			<CFINCLUDE TEMPLATE="Spinup.cfm">
		</CFIF>

		<CFSET BS=Drive.OptimalBlockSize>
		<CFSET DriveBytes=Drive.Attrib.Size.Bytes>
		<CFSET BlockCount=Int(DriveBytes / BS)>
		<CFSET OutDir=PersistDir & "/driveinfo/" & Drive.Config.SaveDir & "/benchmark/" & URL.ScanID>
		<CFIF DirectoryExists(OutDir) EQ "NO">
			<CFDIRECTORY action="create" directory="#OutDir#" mode="666" createpath="yes">
		</CFIF>

		<CFIF Drive.UNRAIDSlot EQ "">
			<CFSET Label=DriveID>
		<CFELSE>
			<CFSET Label=Drive.UNRAIDSLot & " (#DriveID#)">
		</CFIF>

		<CFIF Drive.Attrib.Configuration.RPM EQ "Solid State Device">
			<!--- Wait our turn to benchmark --->
			<CFOUTPUT>SSD Run Slot: #URL.SSDSpot#<br></CFOUTPUT>
			<CFSET Ready=0>
			<CFSET WaitingFlag=0>
			<CFLOOP condition="NOT Ready">
				<CFINCLUDE template="Benchmark_KillCheck.cfm">
				<CFSET ProcessingSlot=0>
				<cflock type="readonly" scope="Application" throwontimeout="false" timeout="10">
					<CFSET ProcessingSlot=Application.SSDSLot>
				</cflock>
				<CFIF ProcessingSlot EQ URL.SSDSpot>
					<CFSET Ready=1>
				<CFELSE>
					<CFIF WaitingFlag EQ 0>
						<CFSET WaitingFlag=0>
						<CFOUTPUT>
						<script>
						parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Waiting';
						</script>
						</CFOUTPUT>
						<CFFLUSH>
					</CFIF>
				</CFIF>
				<!--- Sleep for 1 second --->
				<CFSET Sleep(1000)>
			</CFLOOP>
			<!--- Set Drive Test File Size --->
			<CFIF URL.TestFileSizeOverride EQ 0>
				<CFIF Left(DriveID,4) EQ "nvme">
					<CFSET TestFileSizeFIO=OneGB * 4>
				<CFELSE>
					<CFSET TestFileSizeFIO=OneGB>
				</CFIF>
			<CFELSE>
				<CFSET TestFileSizeFIO=URL.TestFileSizeOverride>
			</CFIF>
			<CFIF MinFreeSpaceAvailable LT TestFileSizeFIO>
				<CFSET MinFreeSpaceAvailable=TestFileSizeFIO>
			</CFIF>
			<!--- Find available mounted partition --->
			<CFSET PartID=0>
			<CFSET MountPoint="">
			<CFSET UUID="">
			<CFLOOP index="i" from="1" to="#ArrayLen(Drive.Partitions.Partitions)#">
				<CFIF Drive.Partitions.Partitions[i].MountPoint NEQ "">
					<CFIF StructKeyExists(Drive.Partitions.Partitions[i],"AvailSpace")>
						<CFIF Drive.Partitions.Partitions[i].AvailSpace GTE OneGB * 5>
							<CFSET PartID=i>
							<CFSET MountPoint=Drive.Partitions.Partitions[i].MountPoint>
							<CFSET UUID=Drive.Partitions.Partitions[i].UUID>
							<CFBREAK>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFLOOP>
			<CFIF PartID GT 0>
				<!---<CFINCLUDE TEMPLATE="Benchmark_IOPing.cfm">--->
				<!--- Create test files --->
				<CFSET MinSpeedMBSec=0>
				<CFSET MaxSpeedMBSec=0>
				<CFSET AvgSpeedMBSec=0>
				<!---<CFSET SSDBS="4M">
				<CFSET SSDBSByte=4000000>--->
				<CFOUTPUT>
				<script language="JavaScript">
				parent.document.getElementById('Progress_#ControllerID#_td').style.display='block';
				parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Trimming drive';
				parent.document.getElementById('Progress_#ControllerID#').value=0;
				parent.document.getElementById('Progress_#ControllerID#_Per').innerHTML='0%';
				</script>
				</CFOUTPUT>
				<CFFLUSH>

				<!--- Execute a sync on the drive --->
				<CFSET SyncBlockDevice(Drive.driveID)>

				<!--- Wait for no disk activity --->
				<CFSET Result=WaitForDriveActivityToStop(Drive.DriveID,1000)>
				<CFOUTPUT>Wait Result [#Result#]<br></CFOUTPUT>
				<CFIF Result EQ 1>
					<CFOUTPUT>
					<script language="JavaScript">
					parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Waiting for Drive Activity to finish';
					</script>
					</CFOUTPUT>
					<CFFLUSH>
					<CFSET WaitForDriveActivityToStop(Drive.DriveID,90000)>
				</CFIF>

				<CFSET DeleteTestFiles(MountPoint)>

				<CFSET TrimSupported=1>
				<CFFILE action="write" file="#OutDir#/trim.sh" mode="766" output="fstrim #MountPoint#" addnewline="NO">
				<CFTRY>
					<CFEXECUTE name="#OutDir#/trim.sh" timeout="3060" />
				<CFCATCH Type="Any">
					<CFOUTPUT>Trim not supported<br></CFOUTPUT>
					<CFSET TrimSupported=0>
				</CFCATCH>
				</CFTRY>

				<CFSET WriteSpeedList="">
				<CFSET TotalTestFiles=0>
				<CFSET EndWrite=0>
				<CFSET AvgMBSecHist=ArrayNew(1)>
				<CFSET TestFiles=0>
				<CFSET MaxMBSec=0>
				<CFSET MinMBSec=0>
				<CFSET BouncyDrive=0>
				<CFSET PerCnt2=0>
				<CFSET CacheDetected=0>
				<CFSET CacheDetectedAt=0>
				<CFLOOP index="i" from="1" to="#SSDBenchmarkTestFiles#">
					<CFINCLUDE template="Benchmark_KillCheck.cfm">

					<!--- Refresh free space available and break out if amount of free space is not sufficient --->
					<CFSET CheckMountPoint=MountPoint>
					<CFINCLUDE template="UpdateMountedFreeSpace.cfm">
					<CFIF CheckMountPointAvailSpace LTE MinSSDSpaceFree>
						<CFBREAK>
					</CFIF>

					<!---
					<CFSET TestFile=MountPoint & "/DiskSpeedTestFile" & Replace(RJustify(i,2)," ","0") & ".jnk">
					<CFSET TestFileCnt=Int(SSDBenchmarkTestFileSize / SSDBSByte)>
					<CFSET ResultsFN=OutDir & "/writefile_" & Replace(RJustify(i,2)," ","0") & "_results.txt">
					<cflock name="TempFiles" type="exclusive" throwontimeout="false" timeout="90">
					<CFFILE action="append" file="/tmp/DiskSpeedTmp/TempFiles.txt" output="#TestFile#" addnewline="yes" mode="666">
					</cflock>
					<CFSET cmd="echo $(($(date +%s%N)/1000000)) > #OutDir#/WriteStartTick.txt" & Chr(10) &
							   "dd if=/dev/zero of=#TestFile# bs=#SSDBS# count=#TestFileCnt# conv=noerror,fdatasync status=progress 2> #ResultsFN#" & Chr(10) &
							   "echo $(($(date +%s%N)/1000000)) > #OutDir#/WriteEndTick.txt" & Chr(10) &
							   "chmod 666 #ResultsFN#" & Chr(10) &
							   "chmod 666 #OutDir#/WriteStartTick.txt" & Chr(10) &
							   "chmod 666 #OutDir#/WriteEndTick.txt" & Chr(10)>
					--->
					<CFSET TestFileChunkSize=Int(TestFileSizeFIO / NRFiles)>
					<CFSET sh="">
					<CFLOOP index="FioID" from="1" to="#NRFiles#">
						<CFSET TestFileID=Replace(RJustify(i,2)," ","0") & "_" & Replace(RJustify(FioID,2)," ","0")>
						<CFSET cmd=FIO>
						<CFSET cmd=Replace(cmd,"[jobid]",TestFileID)>
						<CFSET cmd=Replace(cmd,"[size]",TestFileChunkSize)>
						<CFSET cmd=Replace(cmd,"[dir]",MountPoint)>
						<CFSET cmd=Replace(cmd,"[readwrite]","write")>
						<CFFILE action="write" file="#OutDir#/fio_#i#_#FioID#_write.txt" output="#cmd#" addnewline="NO" mode="766">
						<CFSET sh=sh & "/usr/bin/fio --output-format=json --bandwidth-log #OutDir#/fio_#i#_#FioID#_write.txt > #OutDir#/fio_#i#_#FioID#_write_log.txt &" & Chr(10) &
									   "PID=$!" & Chr(10) &
									   "echo 0 > #OutDir#/$PID.pid" & Chr(10)>

					</CFLOOP>
					<CFSET Per=Int(i / (SSDBenchmarkTestFiles * 2) / 0.01)>
					<CFOUTPUT>
					<script language="JavaScript">
					parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Creating up to #SSDBenchmarkTestFiles# Test Files (#i#/#SSDBenchmarkTestFiles#)';
					parent.document.getElementById('Progress_#ControllerID#').value=#Per#;
					parent.document.getElementById('Progress_#ControllerID#_Per').innerHTML='#Per#%';
					</script>
					<!---dd if=/dev/zero of=#TestFile# bs=#SSDBS# count=#TestFileCnt# conv=noerror,fdatasync status=progress<br>--->
					Write Pass #i#<br>
					</CFOUTPUT><CFFLUSH>
					<CFSET TotalTestFiles=TotalTestFiles + 1>
					<CFSET SHFN="fio_" & GetTickCount() & ".sh">
					<CFFILE action="write" file="#SaveDir#/#SHFN#" output="#sh#" addnewline="no" mode="777">
					<!---<CFEXECUTE name="/usr/bin/fio" arguments="--output-format=json --bandwidth-log #OutDir#/fio_#i#_write.txt" outputFile="#OutDir#/fio_#i#_write_log.txt" timeout="3060" />--->
					<CFSET StartTick=GetTickCount()>
					<CFEXECUTE name="#SaveDir#/#SHFN#" timeout="0"></CFEXECUTE>
					<!--- Wait for log files to be populated --->
					<CFSET OK=0>
					<CFLOOP condition="NOT OK">
						<CFINCLUDE template="Benchmark_KillCheck.cfm">
						<CFDIRECTORY action="list" directory="#OutDir#" name="FlagChk">
						<CFQUERY name="Chk" dbtype="Query">
							SELECT *
							FROM FlagChk
							WHERE Name LIKE 'fio_#i#_%'
							  AND Name LIKE '%_write_log.txt'
							  AND Size > 0
						</CFQUERY>
						<CFIF Chk.RecordCount EQ NRFiles>
							<CFSET OK=1>
						<CFELSE>
							<CFSET Sleep(1000)>
						</CFIF>
					</CFLOOP>
					<!--- Delete PID history of fio jobs --->
					<CFDIRECTORY action="list" directory="#OutDir#" name="PIDs" filter="*.pid">
					<CFLOOP index="PIDCR" from="1" to="#PIDs.RecordCount#">
						<CFTRY>
							<CFFILE action="delete" file="#PIDs.Directory[PIDCR]#/#PIDs.Name[PIDCR]#">
						<CFCATCH Type="Any">
						</CFCATCH>
						</CFTRY>
					</CFLOOP>
					<!--- Wait for any pending writes --->
					<CFSET Result=WaitForDriveActivityToStop(Drive.DriveID)>
					<CFOUTPUT>Write Result: #Result#<br></CFOUTPUT>
					<CFSET BW=0>
					<CFSET BW_Min=0>
					<CFSET BW_Max=0>
					<CFSET BW_Agg=0>
					<CFSET BW_Mean=0>
					<CFLOOP index="FioID" from="1" to="#NRFiles#">
						<CFSET FIOData=LoadJSONFile("#OutDir#/fio_#i#_#FioID#_write_log.txt")>
						<CFLOOP index="JobID" from="1" to="#ArrayLen(FIOData.Jobs)#">
							<CFIF FIOData.Jobs[JobID].Error EQ 1>
								<CFSET TestError=1>
							</CFIF>
							<CFSET BW=BW + FIOData.Jobs[JobID].Write.bw_bytes>
							<CFSET BW_Min=BW_Min + FIOData.Jobs[JobID].Write.BW_Min>
							<CFSET BW_Max=BW_Max + FIOData.Jobs[JobID].Write.BW_Max>
							<CFSET BW_Agg=BW_Agg + FIOData.Jobs[JobID].Write.BW_Agg>
							<CFSET BW_Mean=BW_Mean + FIOData.Jobs[JobID].Write.BW_Mean>
						</CFLOOP>
					</CFLOOP>
					<CFSET BW_Min=BW_Min * 1000>
					<CFSET BW_Max=BW_Max * 1000>
					<CFSET BW_Agg=BW_Agg * 1000>
					<CFSET BW_Mean=BW_Mean * 1000>
					<CFSET SpeedMBSec=BW>
					<CFSET MaxMBSec=Max(MaxMBSec,SpeedMBSec)>
					<CFIF MinMBSec EQ 0>
						<CFSET MinMBSec=SpeedMBSec>
					<CFELSE>
						<CFSET MinMBSec=Min(MinMBSec,SpeedMBSec)>
					</CFIF>


					<CFSET AvgMBSecHist[ArrayLen(AvgMBSecHist)+1]=SpeedMBSec>
					<!--- Check to see if we have exhausted the write cache --->
					<CFSET LowCnt=0>
					<CFSET FoundOutOfCacheRange=0>
					<CFLOOP index="Chk" from="2" to="#ArrayLen(AvgMBSecHist)#">
						<CFSET PerCnt=AvgMBSecHist[Chk] / MaxMBSec / 0.01>
						<CFSET PerCnt2=AvgMBSecHist[Chk] / AvgMBSecHist[Chk - 1] / 0.01>
						<CFIF PerCnt LTE CacheExhaustedPercentage>
							<CFSET FoundOutOfCacheRange=1>
						</CFIF>
						<CFIF PerCnt LTE CacheExhaustedPercentage AND PerCnt2 GTE (100 - SustainedWritePercentage) AND PerCnt2 LTE (100 + SustainedWritePercentage)>
							<CFSET LowCnt=LowCnt + 1>
						<CFELSE>
							<CFSET LowCnt=0>
						</CFIF>
					</CFLOOP>
					<CFIF i GT 1 AND PerCnt2 LTE 50>
						<CFSET CacheDetected=1>
					</CFIF>
					<CFIF LowCnt GTE 2>
						<!--- Sustained Speeds found, exit --->
						<CFSET SSDBenchmarkTestFiles=i>
						<CFSET EndWrite=1>
						<CFSET CacheDetected=1>
					</CFIF>
					<!--- Stop checking after x files if we still haven't identified a cache area and write speeds are bouncy --->
					<CFIF FoundOutOfCacheRange EQ 0 AND TotalTestFiles GTE BenchmarkSSDBounceMinFileCnt>
						<!--- Check for bouncyness --->
						<CFSET BounceCnt=0>
						<CFLOOP index="q" from="2" to="#ArrayLen(AvgMBSecHist)#">
							<CFIF AvgMBSecHist[q] GT AvgMBSecHist[q-1]>
								<CFSET BounceCnt=BounceCnt + 1>
							</CFIF>
						</CFLOOP>
						<CFSET BounceAvg=BounceCnt / ArrayLen(AvgMBSecHist) / 0.01>
						<CFIF BounceAvg GT BenchmarkSSDBounceMinPercentage>
							<CFSET SSDBenchmarkTestFiles=i>
							<CFSET EndWrite=1>
							<CFSET BouncyDrive=1>
						</CFIF>
					</CFIF>

					<CFSET WriteSpeedList=ListAppend(WriteSpeedList,SpeedMBSec)>

					<!--- Checking for bouncing write speeds --->
					<CFSET ChkCnt=0>
					<CFSET ChkTotal=0>
					<CFSET MinSpeedMBSec=0>
					<CFSET MaxSpeedMBSec=0>
					<CFSET PerCnt=0>
					<CFLOOP index="Chk" from="3" to="#ArrayLen(AvgMBSecHist)#">
						<CFSET PerCnt=AvgMBSecHist[Chk] / MaxMBSec / 0.01>
						<CFIF PerCnt GT 80>
							<CFSET ChkCnt=ChkCnt + 1>
							<CFSET ChkTotal=ChkTotal + AvgMBSecHist[Chk]>
							<CFIF MinSpeedMBSec EQ 0>
								<CFSET MinSpeedMBSec=AvgMBSecHist[Chk]>
							<CFELSE>
								<CFSET MinSpeedMBSec=Min(MinSpeedMBSec,AvgMBSecHist[Chk])>
							</CFIF>
							<CFSET MaxSpeedMBSec=Max(MaxSpeedMBSec,AvgMBSecHist[Chk])>
						</CFIF>
					</CFLOOP>
					<CFSET LowSpeedMBSec=AvgMBSecHist[ArrayLen(AvgMBSecHist)]>
					<CFIF ChkCnt GT 0>
						<CFSET WriteAvg=Int(ChkTotal / ChkCnt)>
					<CFELSE>
						<CFSET WriteAvg=LowSpeedMBSec>
					</CFIF>
					<CFIF MinSpeedMBSec EQ 0>
						<CFSET MinSpeedMBSec=AvgMBSecHist[1]>
						<CFSET MaxSpeedMBSec=AvgMBSecHist[1]>
						<CFLOOP index="Chk" from="2" to="#ArrayLen(AvgMBSecHist)#">
							<CFSET MinSpeedMBSec=Min(MinSpeedMBSec,AvgMBSecHist[Chk])>
							<CFSET MaxSpeedMBSec=Max(MaxSpeedMBSec,AvgMBSecHist[Chk])>
						</CFLOOP>
					</CFIF>

					<CFOUTPUT>
					#KBytes(SpeedMBSec)#/Sec<br>
					Min: #KBytes(MinSpeedMBSec)#/Sec, Max: #KBytes(MaxSpeedMBSec)#/Sec, Low Speed: #KBytes(LowSpeedMBSec)#,
					Bouncy: #YesNo(BouncyDrive)#, Cache Detected: #YesNo(CacheDetected)#, ChkCnt: #ChkCnt#,
					PerCnt: #Int(PerCnt)#%, PerCnt2: #Int(PerCnt2)#%<br>
					Bandwidth Min/Max/Agg/Mean: #KBytes(BW_Min)# / #KBytes(BW_Max)# / #KBytes(BW_Agg)# / #KBytes(BW_Mean)#<br>
					<br>
					<script>
					parent.document.getElementById('Speed_#ControllerID#').innerHTML='(#KBytes(SpeedMBSec)#/Sec)';
					</script>
					</CFOUTPUT>
					<CFIF EndWrite EQ 1>
						<CFBREAK>
					</CFIF>
				</CFLOOP>
				<!--- Check if we found a Cache exhaust BUT NOT a persistant write AND no bounce status. --->
				<CFIF (PerCnt LTE CacheExhaustedPercentage AND PerCnt2 LTE SustainedWritePercentage) OR MinSpeedMBSec LT LowSpeedMBSec>
					<CFSET BouncyDrive=1>
				</CFIF>

				<!--- If cache detected, compute burst vs sustained --->
				<CFIF CacheDetected EQ 1>
					<CFSET MinSpeedMBSec=0>
					<CFSET MaxMBSec=0>
					<CFSET WriteAvg=0>
					<CFSET LowMBSec=0>
					<!--- Figure out where write speed drops --->
					<CFLOOP index="q" from="2" to="#ArrayLen(AvgMBSecHist)#">
						<CFIF Int(AvgMBSecHist[q] / AvgMBSecHist[q - 1] / 0.01) LT CacheExhaustedPercentage>
							<CFSET CacheDetectedAt=q - 1>
							<CFBREAK>
						</CFIF>
					</CFLOOP>
					<CFSET Start=CacheDetectedAt + 1>
					<CFIF Start GTE ArrayLen(AvgMBSecHist)>
						<CFSET Start=Start - 1>
					</CFIF>
					<CFSET AvgIdx=0>
					<CFLOOP index="q" from="#Start#" to="#ArrayLen(AvgMBSecHist)#">
						<CFSET AvgIdx=AvgIdx + 1>
						<CFIF MinSpeedMBSec EQ 0>
							<CFSET MinSpeedMBSec=AvgMBSecHist[q]>
						<CFELSE>
							<CFSET MinSpeedMBSec=Min(MinSpeedMBSec,AvgMBSecHist[q])>
						</CFIF>
						<CFSET MaxMBSec=Max(MaxMBSec,AvgMBSecHist[q])>
						<CFSET WriteAvg=WriteAvg + AvgMBSecHist[q]>
					</CFLOOP>
					<CFSET WriteAvg=Int(WriteAvg / AvgIdx)>
					<!--- Sustained write is the average of the last two write MB/s --->
					<CFSET LowMBSec=Int((AvgMBSecHist[ArrayLen(AvgMBSecHist)] + AvgMBSecHist[ArrayLen(AvgMBSecHist)-1]) / 2)>
					<cfoutput>CacheDetectedAt: #CacheDetectedAt# MinSpeedMBSec: #MinSpeedMBSec# MaxMBSec: #MaxMBSec# WriteAvg: #WriteAvg# LowMBSec: #LowMBSec#</cfoutput>
					<!---<cfdump var=#avgmbsechist#>--->
				</CFIF>

				<CFOUTPUT>
				Total Avg: #KBytes(WriteAvg)#/Sec, Max: #KBytes(MaxMBSec)#/Sec<br>
				</CFOUTPUT>
				<!---<CFSET TestFileSizeCreated=SSDBSByte * TotalTestFiles>--->
				<CFFILE action="write" file="#OutDir#/SSDTestFileSize.txt" output="#TestFileSizeFIO#" addnewline="NO" mode="666">
				<CFIF BouncyDrive EQ 1 OR CacheDetected EQ 0>
					<CFFILE action="write" file="#OutDir#/SSDWriteSpeed.txt" output="#WriteAvg#|#MinMBSec#|#MaxMBSec#" addnewline="NO" mode="666">
					<CFSET WriteMin=MinMBSec>
				<CFELSE>
					<CFFILE action="write" file="#OutDir#/SSDWriteSpeed.txt" output="#WriteAvg#|#MinSpeedMBSec#|#MaxMBSec#|#LowSpeedMBSec#" addnewline="NO" mode="666">
					<CFSET WriteMin=MinSpeedMBSec>
				</CFIF>
				<CFFILE action="write" file="#OutDir#/SSDWriteSpeedList.txt" output="#WriteSpeedList#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/BouncyDrive.txt" output="#BouncyDrive#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/CacheDetected.txt" output="#CacheDetected#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/CacheDetectedAt.txt" output="#CacheDetectedAt#" addnewline="NO" mode="666">
				<CFSET WriteMax=MaxSpeedMBSec>


				<CFOUTPUT>
				<script language="JavaScript">
				parent.Chart1.series[#ChartSlot+1#].addPoint([#CurrSSDSpot#,#MinSpeedMBSec#,#MinSpeedMBSec#,#WriteAvg#,#MaxSpeedMBSec#,#MaxSpeedMBSec#]);
				parent.document.getElementById('Speed_#ControllerID#').innerHTML='#KBytes(WriteAvg)#/Sec';
				parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Waiting for test files to finish writing to drive';
				</script>
				<br>
				<!---<br>Chart1.series[#ChartSlot+1#].addPoint([#CurrSSDSpot#,#MinSpeedMBSec#,#MinSpeedMBSec#,#WriteAvg#,#MaxSpeedMBSec#,#MaxSpeedMBSec#]);<br>--->
				</CFOUTPUT>
				<CFFLUSH>
				<CFSET CurrSSDSpot=CurrSSDSpot - RMinus>

				<CFSET Start=GetTickCount()>
				<CFSET FlushTestFiles(MountPoint)>
				<CFSET TotalMS=GetTickCount() - Start>
				<CFOUTPUT>
				Sync took #TotalMS# ms<br>
				</CFOUTPUT>

				<CFIF URL.WaitBeforeRead GT 0>
					<CFLOOP index="i" from="#URL.WaitBeforeRead#" to="1" step="-1">
						<CFOUTPUT>
						<script language="JavaScript">
						parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Waiting #i# second<CFIF i NEQ 1>s</CFIF> before starting the read tests';
						</script>
						</CFOUTPUT>
						<CFFLUSH>
						<CFSET Sleep(1000)>
					</CFLOOP>
				</CFIF>


				<!--- Read test files --->
				<CFSET MinSpeedMBSec=0>
				<CFSET MaxSpeedMBSec=0>
				<CFSET AvgSpeedMBSec=0>
				<CFSET ReadSpeedList="">
				<CFLOOP index="i" from="1" to="#TotalTestFiles#">
					<CFINCLUDE template="Benchmark_KillCheck.cfm">
					<!---
					<CFSET TestFile=MountPoint & "/DiskSpeedTestFile" & Replace(RJustify(i,2)," ","0") & ".jnk">
					<CFSET ResultsFN=OutDir & "/Readfile_" & Replace(RJustify(i,2)," ","0") & "_results.txt">
					<CFSET cmd="echo $(($(date +%s%N)/1000000)) > #OutDir#/ReadStartTick.txt" & Chr(10) &
							   "dd if=#TestFile# of=/dev/null iflag=direct conv=noerror status=progress 2> #ResultsFN#" & Chr(10) &
							   "echo $(($(date +%s%N)/1000000)) > #OutDir#/ReadEndTick.txt" & Chr(10) &
							   "rm #TestFile#" & Chr(10) &
							   "chmod 666 #ResultsFN#" & Chr(10) &
							   "chmod 666 #OutDir#/ReadStartTick.txt" & Chr(10) &
							   "chmod 666 #OutDir#/ReadEndTick.txt" & Chr(10)>
					--->
					<CFSET TestFileChunkSize=Int(TestFileSizeFIO / NRFiles)>
					<CFSET sh="">
					<CFLOOP index="FioID" from="1" to="#NRFiles#">
						<CFSET TestFileID=Replace(RJustify(i,2)," ","0") & "_" & Replace(RJustify(FioID,2)," ","0")>
						<CFSET cmd=FIO>
						<CFSET cmd=Replace(cmd,"[jobid]",TestFileID)>
						<CFSET cmd=Replace(cmd,"[size]",TestFileChunkSize)>
						<CFSET cmd=Replace(cmd,"[dir]",MountPoint)>
						<CFSET cmd=Replace(cmd,"[readwrite]","read")>
						<CFFILE action="write" file="#OutDir#/fio_#i#_#FioID#_read.txt" output="#cmd#" addnewline="NO" mode="766">
						<CFSET sh=sh & "/usr/bin/fio --output-format=json --bandwidth-log #OutDir#/fio_#i#_#FioID#_read.txt > #OutDir#/fio_#i#_#FioID#_read_log.txt &" & Chr(10) &
									   "PID=$!" & Chr(10) &
									   "echo 0 > #OutDir#/$PID.pid" & Chr(10)>
					</CFLOOP>

					<CFSET Per=Int((i + TotalTestFiles) / (TotalTestFiles * 2) / 0.01)>
					<CFOUTPUT>
					<script language="JavaScript">
					parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: #Label# - Reading #TotalTestFiles# Test Files (#i#/#TotalTestFiles#)';
					parent.document.getElementById('Progress_#ControllerID#').value=#Per#;
					parent.document.getElementById('Progress_#ControllerID#_Per').innerHTML='#Per#%';
					</script>
					<!---dd if=#TestFile# of=/dev/null iflag=direct conv=noerror status=progress<br>--->
					<!---/usr/bin/fio --output-format=json+ --bandwidth-log #OutDir#/fio_#i#_read.txt<br>--->
					Read Pass #i#<br>
					</CFOUTPUT><CFFLUSH>
					<!---
					<CFFILE action="write" file="#OutDir#/fio_#i#_read.txt" output="#cmd#" addnewline="NO" mode="766">
					<CFEXECUTE name="/usr/bin/fio" arguments="--output-format=json+ --bandwidth-log #OutDir#/fio_#i#_read.txt" outputFile="#OutDir#/fio_#i#_read_log.txt" timeout="3060" />
					--->
					<CFSET SHFN="fio_" & GetTickCount() & ".sh">
					<CFFILE action="write" file="#SaveDir#/#SHFN#" output="#sh#" addnewline="no" mode="777">
					<CFEXECUTE name="#SaveDir#/#SHFN#" timeout="0"></CFEXECUTE>
					<!--- Wait for log files to be populated --->
					<CFSET OK=0>
					<CFLOOP condition="NOT OK">
						<CFINCLUDE template="Benchmark_KillCheck.cfm">
						<CFDIRECTORY action="list" directory="#OutDir#" name="FlagChk">
						<CFQUERY name="Chk" dbtype="Query">
							SELECT *
							FROM FlagChk
							WHERE Name LIKE 'fio_#i#_%'
							  AND Name LIKE '%_read_log.txt'
							  AND Size > 0
						</CFQUERY>
						<CFIF Chk.RecordCount EQ NRFiles>
							<CFSET OK=1>
						<CFELSE>
							<CFSET Sleep(1000)>
						</CFIF>
					</CFLOOP>
					<!--- Delete PID history of fio jobs --->
					<CFDIRECTORY action="list" directory="#OutDir#" name="PIDs" filter="*.pid">
					<CFLOOP index="PIDCR" from="1" to="#PIDs.RecordCount#">
						<CFTRY>
							<CFFILE action="delete" file="#PIDs.Directory[PIDCR]#/#PIDs.Name[PIDCR]#">
						<CFCATCH Type="Any">
						</CFCATCH>
						</CFTRY>
					</CFLOOP>

					<!---<CFSET FIOData=LoadJSONFile("#OutDir#/fio_#i#_read_log.txt")>--->
					<CFSET BW=0>
					<CFSET BW_Min=0>
					<CFSET BW_Max=0>
					<CFSET BW_Agg=0>
					<CFSET BW_Mean=0>
					<CFLOOP index="FioID" from="1" to="#NRFiles#">
						<CFSET FIOData=LoadJSONFile("#OutDir#/fio_#i#_#FioID#_read_log.txt")>
						<CFLOOP index="JobID" from="1" to="#ArrayLen(FIOData.Jobs)#">
							<CFIF FIOData.Jobs[JobID].Error EQ 1>
								<CFSET TestError=1>
							</CFIF>
							<CFSET BW=BW + FIOData.Jobs[JobID].Read.bw_bytes>
							<CFSET BW_Min=BW_Min + FIOData.Jobs[JobID].Read.BW_Min>
							<CFSET BW_Max=BW_Max + FIOData.Jobs[JobID].Read.BW_Max>
							<CFSET BW_Agg=BW_Agg + FIOData.Jobs[JobID].Read.BW_Agg>
							<CFSET BW_Mean=BW_Mean + FIOData.Jobs[JobID].Read.BW_Mean>
						</CFLOOP>
					</CFLOOP>
					<CFSET BW_Min=BW_Min * 1000>
					<CFSET BW_Max=BW_Max * 1000>
					<CFSET BW_Agg=BW_Agg * 1000>
					<CFSET BW_Mean=BW_Mean * 1000>
					<!---<CFSET SpeedMBSec=BW * 1000>--->
					<CFSET SpeedMBSec=BW>

					<CFSET ReadSpeedList=ListAppend(ReadSpeedList,SpeedMBSec)>
					<CFIF MinSpeedMBSec EQ 0>
						<CFSET MinSpeedMBSec=SpeedMBSec>
					<CFELSE>
						<CFSET MinSpeedMBSec=Min(MinSpeedMBSec,SpeedMBSec)>
					</CFIF>
					<CFSET MaxSpeedMBSec=Max(MaxSpeedMBSec,SpeedMBSec)>
					<CFSET AvgSpeedMBSec=AvgSpeedMBSec + SpeedMBSec>
					<CFOUTPUT>
					#KBytes(SpeedMBSec)#/Sec<br>
					Min: #KBytes(MinSpeedMBSec)#/Sec Max: #KBytes(MaxSpeedMBSec)#/Sec<br>
					BW Min/Max/Agg/Mean: #KBytes(BW_Min)# / #KBytes(BW_Max)# / #KBytes(BW_Agg)# / #KBytes(BW_Mean)#<br>
					<br>
					<script>
					parent.document.getElementById('Speed_#ControllerID#').innerHTML='(#KBytes(SpeedMBSec)#/Sec)';
					</script>
					</CFOUTPUT>
				</CFLOOP>
				<CFSET ReadAvg=AvgSpeedMBSec / TotalTestFiles>
				<CFOUTPUT>Total Avg: #KBytes(ReadAvg)#/Sec<br> Min: #KBytes(MinSpeedMBSec)#/Sec Max: #KBytes(MaxSpeedMBSec)#/Sec</CFOUTPUT>
				<CFFILE action="write" file="#OutDir#/SSDReadSpeed.txt" output="#ReadAvg#|#MinSpeedMBSec#|#MaxSpeedMBSec#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/SSDReadSpeedList.txt" output="#ReadSpeedList#" addnewline="NO" mode="666">

				<CFOUTPUT>
				<script language="JavaScript">
				parent.Chart1.series[#ChartSlot#].addPoint([#CurrSSDSpot#,#MinSpeedMBSec#,#MinSpeedMBSec#,#ReadAvg#,#MaxSpeedMBSec#,#MaxSpeedMBSec#]);
				</script>
				<br>Chart1.series[#ChartSlot#].addPoint([#CurrSSDSpot#,#MinSpeedMBSec#,#MinSpeedMBSec#,#ReadAvg#,#MaxSpeedMBSec#,#MaxSpeedMBSec#]);<br>
				</CFOUTPUT>
				<CFSET CurrSSDSpot=CurrSSDSpot - NMinus>

				<CFFILE action="write" file="#OutDir#/valid.txt" output="" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/0000000000000000.txt" output="" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/datestamp.txt" output="#Now()#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/version.txt" output="#Version#" addnewline="NO" mode="666">
				<CFFILE action="write" file="#OutDir#/CacheDetected.txt" output="#CacheDetected#" addnewline="NO" mode="666">
				<CFSET tmp='{"COLUMNS":["id","Drive","DateStamp","Spot","Speed"],"DATA":[]}'>
				<CFFILE action="write" file="#OutDir#/speed.json" output="#tmp#" addnewline="NO" mode="666">

				<!--- Save results to HW --->
				
				<CFIF FileExists("#PersistDir#/storage.json")>
					<cflock name="CreateFile" type="exclusive" throwontimeout="false" timeout="10">
						<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
						<CFSET HW=DeserializeJSON(json)>
						<CFIF StructKeyExists(HW[Key].Ports[PortNo],"SSD_Benchmark") EQ "No">
							<CFSET HW[Key].Ports[PortNo].SSD_Benchmark=StructNew()>
						<CFELSE>
							<!--- Take previous scans into account --->
							<!---
							<CFSET MinSpeedMBSec=Min(MinSpeedMBSec,HW[Key].Ports[PortNo].SSD_Benchmark.ReadMin)>
							<CFSET MaxSpeedMBSec=Max(MaxSpeedMBSec,HW[Key].Ports[PortNo].SSD_Benchmark.ReadMax)>
							<CFSET ReadAvg=Int((ReadAvg + HW[Key].Ports[PortNo].SSD_Benchmark.ReadAvg) / 2)>
							<CFSET WriteMin=Min(WriteMin,HW[Key].Ports[PortNo].SSD_Benchmark.WriteMin)>
							<CFSET WriteMax=Max(WriteMax,HW[Key].Ports[PortNo].SSD_Benchmark.WriteMax)>
							<CFSET WriteAvg=Int((WriteAvg + HW[Key].Ports[PortNo].SSD_Benchmark.WriteAvg) / 2)>
							<CFSET LowSpeedMBSec=Int((LowSpeedMBSec + HW[Key].Ports[PortNo].SSD_Benchmark.WriteLow) / 2)>
							--->
						</CFIF>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadMin=MinSpeedMBSec>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadMax=MaxSpeedMBSec>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.ReadAvg=ReadAvg>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteMin=WriteMin>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteMax=WriteMax>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteAvg=WriteAvg>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.WriteLow=LowSpeedMBSec>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.Bouncy=BouncyDrive>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetected=CacheDetected>
						<CFSET HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetectedAt=CacheDetectedAt>
						<CFSET HW[Key].Ports[PortNo].TrimSupported=TrimSupported>
						<CFSET json=SerializeJSON(HW)>
						<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
					</cflock>
				</CFIF>

				<CFSET ScannedSSD=ScannedSSD + 1>
				<CFIF ScannedSSD GTE TotalSSD>
					<!--- Signal next SSD test can run --->
					<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="10">
						<CFSET Application.SSDSlot=Application.SSDSlot + 1>
					</cflock>
				</CFIF>

				<CFSET DeleteTestFiles(MountPoint)>
			<CFELSE>
				<!--- Can't benchmark this drive, signal next drive to start --->
				<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="10">
					<CFSET Application.SSDSlot=Application.SSDSlot + 1>
				</cflock>
			</CFIF>


		<CFELSE>
			<!---<CFINCLUDE TEMPLATE="Benchmark_IOPing.cfm">--->
			<CFSET ScanLoc="0">
			<CFSET TotalSpots=0>
			<CFSET CurrSpot=0>
			<CFSET AdjustBlocks=0>
			<CFSET SpeedDiff=ArrayNew(2)>
			<CFSET NotValid=0>
			<CFLOOP index="Spot" from="0" to="100" step="#URL.Per#">
				<CFSET TotalSpots=TotalSpots + 1>
			</CFLOOP>
			<CFLOOP index="Spot" from="0" to="100" step="#URL.Per#">
				<CFSET OK=0>
				<CFSET Spot2=Replace(RJustify(Spot,3)," ","0","ALL")>
				<CFSET CurrSpot=CurrSpot + 1>
				<CFSET Retry=0>
				<CFIF URL.DisableSpeedGap EQ "0">
					<CFSET MaxGap=45000000>
				<CFELSE>
					<CFSET MaxGap=0>
				</CFIF>
				<CFLOOP condition="NOT OK">
					<CFINCLUDE template="Benchmark_KillCheck.cfm">

					<CFSET ScanLoc=Int(BlockCount * (Spot * 0.01))>
					<CFSET ScanLoc=Int(DriveBytes * (Spot * 0.01) / BS)>
					<CFIF AdjustBlocks GT 0>
						<CFSET ScanLoc=ScanLoc - AdjustBlocks>
					</CFIF>
					<CFSET SizeLoc=KBytes(BS * ScanLoc)>
					<CFSET ByteLoc=Replace(RJustify(BS * ScanLoc,16)," ","0","ALL")>
					<CFIF Spot EQ 0>
						<CFSET SizeLoc="0 GB">
					<CFELSEIF ListLast(SizeLoc," ") EQ "GB">
						<CFSET SizeLoc=ListFirst(SizeLoc,".") & " GB">
					<CFELSEIF ListLast(SizeLoc," ") EQ "TB">
						<CFSET SizeLoc=Val(ListFirst(SizeLoc," ")) & " TB">
					</CFIF>
					<CFSET ResultsFN=OutDir & "/read_spot_#Spot2#_results.txt">
					<CFIF Retry EQ 0>
						<CFSET Per=Int((CurrSpot - 1) / TotalSpots / 0.01)>
						<CFOUTPUT>
						<script language="JavaScript">
						parent.document.getElementById('Progress_#ControllerID#_td').style.display='block';
						parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Scanning #Label# at #SizeLoc#';
						parent.document.getElementById('Progress_#ControllerID#').value=#Spot#;
						parent.document.getElementById('Progress_#ControllerID#_Per').innerHTML='#Per#%';
						</script>
						</CFOUTPUT><CFFLUSH>
					<CFELSE>
						<CFSET MaxGap=MaxGap + 5000000>
					</CFIF>
					<CFIF AdjustBlocks EQ 0>
						<CFOUTPUT>CMD: dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=#ScanLoc# iflag=direct conv=noerror status=progress<br>
						#TS()# Spot: [#Spot#] ScanLoc: [#ScanLoc#] SizeLoc: [#SizeLoc#] </CFOUTPUT><CFFLUSH>
						<CFSET cmd="dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=#ScanLoc# iflag=direct conv=noerror status=progress 2> #ResultsFN# &" & Chr(10) &
								"PID=$!" & Chr(10) &
								"echo 0 > #SaveDir#/pids/$PID" & Chr(10) &
								"sleep #URL.Seconds+1#" & Chr(10) &
								"kill $PID" & Chr(10) &
								"rm #SaveDir#/pids/$PID" & Chr(10) &
								"sleep 1" & Chr(10) &
								"chmod 666 #ResultsFN#" & Chr(10)>
						<CFFILE action="write" file="#OutDir#/read_spot_#Spot2#.sh" mode="766" output="#cmd#" addnewline="NO">
						<CFEXECUTE name="#OutDir#/read_spot_#Spot2#.sh" timeout="3060" />
						<CFSET Result=GetReadAvg(ResultsFN,Drive.Attrib.Configuration.RPM,2,MaxGap)>
					<CFELSE>
						<CFOUTPUT>CMD: dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=#ScanLoc# iflag=direct conv=noerror status=progress<br>
						#TS()# Spot: [#Spot#] ScanLoc: [#ScanLoc#] SizeLoc: [#SizeLoc#] </CFOUTPUT><CFFLUSH>
						<CFSET cmd="dd if=/dev/#DriveID# of=/dev/null bs=#BS# skip=#ScanLoc# iflag=direct conv=noerror status=progress 2> #ResultsFN#" & Chr(10) &
								"chmod 666 #ResultsFN#" & Chr(10)>
						<CFFILE action="write" file="#OutDir#/read_spot_#Spot2#.sh" mode="766" output="#cmd#" addnewline="NO">
						<CFEXECUTE name="#OutDir#/read_spot_#Spot2#.sh" timeout="3060" />
						<CFFILE action="read" file="#ResultsFN#" variable="Data">
						<CFSET Skip=ListLen(Data,Chr(13)) - URL.Seconds - 2>
						<CFIF Skip LT 0>
							<CFSET Skip=0>
						</CFIF>
						<CFOUTPUT>SkipLines: [#Skip#] </CFOUTPUT><CFFLUSH>
						<CFSET Result=GetReadAvg(ResultsFN,Drive.Attrib.Configuration.RPM,Skip,MaxGap+MaxGap)>
					</CFIF>
					<CFIF Val(Result) GT 0>
						<CFSET OK=1>
						<CFSET Avg=ListFirst(Result,"|")>
						<CFSET AvgMin=ListGetAt(Result,2,"|")>
						<CFSET AvgMax=ListLast(Result,"|")>
						<CFIF CurrSpot EQ 1>
							<CFSET SpeedDiff[1][1]=Avg>
							<CFSET SpeedDiff[1][2]=0>
						<CFELSE>
							<CFSET SpeedDiff[CurrSpot][1]=Avg>
							<CFSET SpeedDiff[CurrSpot][2]=100 - (Avg / SpeedDiff[CurrSpot-1][1]) / 0.01>
							<!--- <CFIF SpeedDiff[CurrSpot] LT 0>
								<CFSET SpeedDiff[CurrSpot]=0>
							</CFIF> --->
						</CFIF>
					<CFELSE>
						<CFSET Retry=Retry + 1>
						<CFSET Per=Int((CurrSpot - 1) / TotalSpots / 0.01)>
						<CFOUTPUT>
						<script language="JavaScript">
						parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Scanning #Label# at #SizeLoc# - #Result# (#Retry#)';
						parent.document.getElementById('Progress_#ControllerID#').value=#Spot#;
						parent.document.getElementById('Progress_#ControllerID#_Per').innerHTML='#Per#%';
						<CFIF Find("Speed Gap",Result)>
							parent.document.getElementById('SpeedGapDetected').style.display='block';
						</CFIF>
						</script>
						<CFIF Result EQ "0|9999999999|0">
							<!--- Drive is not reading, bad, break out --->
							<CFSET OK=1>
							<CFSET NotValid=1>
							<CFOUTPUT><br>#TS()# Drive is not reading, aborting benchmark<br><br></CFOUTPUT>
							<CFBREAK>
						</CFIF>
						#Result#<br>
						</CFOUTPUT><CFFLUSH>
					</CFIF>
				</CFLOOP>
				<CFIF NotValid EQ 1>
					<CFBREAK>
				</CFIF>
				<CFIF Spot EQ 100>
					<CFFILE action="write" file="#OutDir#/#DriveBytes#.txt" output="#Avg#" addnewline="NO" mode="666">
				<CFELSE>
					<CFFILE action="write" file="#OutDir#/#ByteLoc#.txt" output="#Avg#" addnewline="NO" mode="666">
				</CFIF>
				<CFOUTPUT>Avg: [#KBytes(Avg)#] AvgMin: [#KBytes(AvgMin)#] AvgMax: [#KBytes(AvgMax)#] </CFOUTPUT><CFFLUSH>
				<CFIF CurrSpot EQ TotalSpots - 1>
					<!--- Identify total blocks read and adjust for the end of the drive --->
					<CFFILE action="read" file="#ResultsFN#" variable="Data">
					<CFSET TotalBytes=ListFirst(ListLast(Data,Chr(13))," ")>
					<CFSET AdjustBlocks=Int(TotalBytes / BS)>
					<CFOUTPUT>Total Bytes: [#TotalBytes#] Adjust [#AdjustBlocks#] </CFOUTPUT><CFFLUSH>
				</CFIF>
				<cfoutput><br></cfoutput>
				<CFSET ByteSpot=ScanLoc * BS>
				<CFOUTPUT>
				<script language="JavaScript">
				parent.Chart1.series[#ChartSlot#].addPoint([#ByteSpot#,#Avg#]);
				//parent.Chart2.series[#ChartSlot#].addPoint([#Spot#,#Avg#]);
				</script>
				Chart1.series[#ChartSlot#].addPoint([#ByteSpot#,#Avg#]);<br>
				parent.document.getElementById('Speed_#ControllerID#').innerHTML='';
				</CFOUTPUT>
				<CFFLUSH>


			</CFLOOP>

			<CFIF FileExists("#PersistDir#/driveinfo/DriveBenchmarks.txt")>
				<CFFILE action="delete" file="#PersistDir#/driveinfo/DriveBenchmarks.txt">
			</CFIF>

			<CFIF NotValid EQ 0>
				<CFFILE action="write" file="#OutDir#/valid.txt" mode="666" output="" addnewline="NO">
			</CFIF>
			<CFIF TotalSpots NEQ 10>
				<CFFILE action="write" file="#OutDir#/nosubmit.txt" mode="666" output="" addnewline="NO">
			</CFIF>

			<!--- <cfdump var=#drive#> --->

			<CFSET Flatline=0>
			<CFLOOP index="CR" from="2" to="#ArrayLen(SpeedDiff)#">
				<CFIF Abs(SpeedDiff[CR][2]) LT 3>
					<CFSET Flatline=Flatline + 1>
				</CFIF>
			</CFLOOP>
			<!--- Don't submit pool/raid benchmarks --->
			<CFIF ListFindNoCase(PoolMembers,DriveID)>
				<CFFILE action="write" file="#OutDir#/nosubmit.txt" mode="666" output="" addnewline="NO">
			</CFIF>
			<!--- Don't submit bandwidth capped devices --->
			<CFIF FlatLine GT 3>
				<CFFILE action="write" file="#OutDir#/nosubmit.txt" mode="666" output="" addnewline="NO">
				<CFFILE action="write" file="#OutDir#/bandwidthcapped.txt" mode="666" output="" addnewline="NO">
				<CFOUTPUT>
				Bandwidth cap detected on #Flatline# checks<br>
				<script language="JavaScript">parent.BandwidthCap('#Label#');</script>
				</CFOUTPUT>
			<CFELSE>
				<CFIF FileExists("#OutDir#/bandwidthcapped.txt")>
					<CFFILE action="delete" file="#OutDir#/bandwidthcapped.txt">
				</CFIF>
			</CFIF>
		</CFIF>

	</CFIF>
</CFLOOP>

<CFOUTPUT>
<script language="JavaScript">
parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Done';
parent.document.getElementById('Progress_#ControllerID#_td').style.display='none';
parent.document.getElementById('Speed_#ControllerID#').innerHTML='';
parent.SubTest();
</script>
<br>
#TS()# Benchmark complete.
</CFOUTPUT>
<CFFLUSH>
<CFTRY>
	<CFFILE action="delete" file="#BenchmarkFlagFN#">
<CFCATCH Type="Any">
</CFCATCH>
</CFTRY>


<CFCATCH Type="Any">
	<CFSET ControllerID="controller_" & Replace(Replace(URL.Controller,":","_","ALL"),".","_","ALL") & "_debug">
	<CFOUTPUT>
	<script language="JavaScript">
	parent.document.getElementById('#ControllerID#').style.display='block';
	parent.document.getElementById('AbortButton1').click();

	//parent.document.getElementById('AbortButton1').style.display='none';
	//parent.document.getElementById('AbortButton2').style.display='none';
	//parent.document.getElementById('AbortButton3').style.display='block';
	</script>
	</CFOUTPUT>
	<CFINCLUDE template="Benchmark_KillCheck.cfm">
	<CFINCLUDE template="error.cfm">
	<cfflush>
	<CFTRY>
		<CFFILE action="delete" file="#BenchmarkFlagFN#">
	<CFCATCH Type="Any">
	</CFCATCH>
	</CFTRY>
</CFCATCH>
</CFTRY>
<cflock name="ProcessBench" type="exclusive" throwontimeout="false" timeout="10">

<CFSET DriveDir=PersistDir & "/driveinfo">
<CFDIRECTORY action="List" directory="#DriveDir#" name="Drives" type="dir">

<CFSET AllDrives=QueryNew("Drive,DateStamp,Spot,Speed","varchar,date,bigint,bigint")>

<CFLOOP index="DriveID" from="1" to="#Drives.RecordCount#">
	<CFSET BenchDir="#DriveDir#/#Drives.Name[DriveID]#/benchmark">
	<CFIF DirectoryExists(BenchDir)>
		<CFDIRECTORY action="list" directory="#BenchDir#" type="dir" name="Bench">
		<CFSET BenchProcessed=0>
		<CFLOOP index="BenchID" from="1" to="#Bench.RecordCount#">
			<CFIF FileExists("#BenchDir#/#Bench.Name[BenchID]#/valid.txt") EQ "NO" OR FileExists("#BenchDir#/#Bench.Name[BenchID]#/0000000000000000.txt") EQ "NO">
				<cflock name="FileDelete" type="exclusive" throwontimeout="false" timeout="5">
				<CFTRY>
					<CFDIRECTORY action="delete" directory="#BenchDir#/#Bench.Name[BenchID]#" recurse="true">
				<CFCATCH Type="Any">
				</CFCATCH>
				</CFTRY>
				</cflock>
			<CFELSE>
				<CFDIRECTORY action="list" directory="#BenchDir#/#Bench.Name[BenchID]#" filter="read_spot*.*|*_read.txt" name="KillFiles">
				<CFLOOP index="fileidx" from="1" to="#KillFiles.RecordCount#">
					<cflock name="FileDelete" type="exclusive" throwontimeout="false" timeout="5">
						<CFIF FileExists("#BenchDir#/#Bench.Name[BenchID]#/#KillFiles.Name[fileidx]#")>
							<CFTRY>
								<CFFILE action="delete" file="#BenchDir#/#Bench.Name[BenchID]#/#KillFiles.Name[fileidx]#">
							<CFCATCH Type="Any">
							</CFCATCH>
							</CFTRY>
						</CFIF>
					</cflock>
				</CFLOOP>
				<CFIF FileExists("#BenchDir#/#Bench.Name[BenchID]#/datestamp.txt") EQ "NO">
					<CFSET BenchProcessed=1>
					<CFDIRECTORY action="list" directory="#BenchDir#/#Bench.Name[BenchID]#" name="Results" type="file" sort="datelastmodified">
					<CFSET Speed=QueryNew("id,Drive,DateStamp,Spot,Speed","integer,varchar,date,bigint,bigint")>
					<CFLOOP index="CF" from="1" to="#Results.RecordCount#">
						<CFIF IsNumeric(ListFirst(Results.Name[CF],"."))>
							<CFFILE action="read" file="#BenchDir#/#Bench.Name[BenchID]#/#Results.Name[CF]#" variable="ReadSpeed">
							<CFSET QueryAddRow(Speed)>
							<CFSET QuerySetCell(Speed,"id",CF)>
							<CFSET QuerySetCell(Speed,"Drive",Drives.Name[DriveID])>
							<CFSET QuerySetCell(Speed,"DateStamp",Results.DateLastModified[1])>
							<CFSET QuerySetCell(Speed,"Spot",Val(ListFirst(Results.Name[CF],".")))>
							<CFSET QuerySetCell(Speed,"Speed",ReadSpeed)>
						</CFIF>
					</CFLOOP>
					<!--- <cfdump var=#speed#> --->
					<CFSET json=SerializeJSON(Speed)>
					<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
						<CFFILE action="write" file="#BenchDir#/#Bench.Name[BenchID]#/speed.json" output="#json#" addnewline="NO" mode="666">
						<CFFILE action="write" file="#BenchDir#/#Bench.Name[BenchID]#/datestamp.txt" output="#Results.DateLastModified[1]#" addnewline="NO" mode="666">
						<CFFILE action="write" file="#BenchDir#/#Bench.Name[BenchID]#/version.txt" output="#Version#" addnewline="NO" mode="666">
					</cflock>
				</CFIF>
			</CFIF>
		</CFLOOP>
		<CFIF BenchProcessed EQ 1>
			<CFDIRECTORY action="list" directory="#BenchDir#" filter="speed.json" recurse="true" name="SpeedFiles">
			<CFSET Speed=QueryNew("id,Drive,DateStamp,Spot,Speed","varchar,integer,date,bigint,bigint")>
			<CFSET SpeedAvg=QueryNew("Spot,AvgSpeed,MinSpeed,MaxSpeed","bigint,bigint,bigint,bigint")>
			<CFLOOP index="SCR" from="1" to="#SpeedFiles.RecordCount#">
				<CFFILE action="read" file="#SpeedFiles.Directory[SCR]#/speed.json" variable="json">
				<CFSET test=DeserializeJSON(json,false)>
				<CFQUERY name="tmp" dbtype="query">
					SELECT id,Drive,DateStamp,Spot,Speed
					FROM Speed
					UNION
					SELECT id,Drive,DateStamp,Spot,Speed
					FROM test
				</CFQUERY>
				<CFSET Speed=Duplicate(tmp)>
			</CFLOOP>
			<CFQUERY name="Spots" dbtype="Query">
				SELECT DISTINCT Spot
				FROM Speed
				ORDER BY Spot
			</CFQUERY>
			<CFLOOP index="SpotIdx" from="1" to="#Spots.RecordCount#">
				<CFQUERY name="Tot" dbtype="Query">
					SELECT SUM(Speed) AS TotSpeed, MIN(Speed) AS MinSpeed, MAX(Speed) as MaxSpeed
					FROM Speed
					WHERE Spot=#Spots.Spot[SpotIdx]#
				</CFQUERY>
				<CFQUERY name="Cnt" dbtype="Query">
					SELECT COUNT(*) AS Cnt
					FROM Speed
					WHERE Spot=#Spots.Spot[SpotIdx]#
				</CFQUERY>
				<CFSET Avg=Int(Tot.TotSpeed / Cnt.Cnt)>
				<CFSET QueryAddRow(SpeedAvg)>
				<CFSET QuerySetCell(SpeedAvg,"Spot",Spots.Spot[SpotIdx])>
				<CFSET QuerySetCell(SpeedAvg,"AvgSpeed",Avg)>
				<CFSET QuerySetCell(SpeedAvg,"MinSpeed",Tot.MinSpeed)>
				<CFSET QuerySetCell(SpeedAvg,"MaxSpeed",Tot.MaxSpeed)>
			</CFLOOP>
			<CFSET json=SerializeJSON(Speed)>
			<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
				<CFFILE action="write" file="#BenchDir#/allspeed.json" output="#json#" addnewline="NO" mode="666">
			</cflock>
			<CFSET json=SerializeJSON(SpeedAvg)>
			<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
				<CFFILE action="write" file="#BenchDir#/avgspeed.json" output="#json#" addnewline="NO" mode="666">
			</cflock>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFLOOP index="Key" list="#StructKeyList(HW)#">
	<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
		<CFIF HW[Key].Ports[PortNo].DriveID NEQ "">
			<CFIF HW[Key].Ports[PortNo].CDROM EQ 0>
				<CFSET FN=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>
				<CFIF FileExists("#FN#/benchmark/allspeed.json")>
					<CFFILE action="read" file="#FN#/benchmark/allspeed.json" variable="json">
					<CFSET tmp=DeserializeJSON(json,false)>
					<CFQUERY name="MaxDate" dbtype="Query">
						SELECT MAX(DateStamp) as MaxDate
						FROM tmp
					</CFQUERY>
					<CFQUERY name="tmp2" dbtype="Query">
						SELECT Drive,DateStamp,Spot,Speed
						FROM AllDrives
						UNION
						SELECT Drive,DateStamp,Spot,Speed
						FROM tmp
						WHERE Drive='#HW[Key].Ports[PortNo].Config.SaveDir#'
						AND DateStamp=#CreateODBCDateTime(MaxDate.MaxDate)#
					</CFQUERY>
					<CFSET AllDrives=Duplicate(tmp2)>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFLOOP>
</CFLOOP>

<CFSET json=SerializeJSON(AllDrives)>
<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
	<CFFILE action="write" file="#DriveDir#/drivebenchmarks.json" output="#json#" addnewline="NO" mode="666">
</cflock>

</cflock>

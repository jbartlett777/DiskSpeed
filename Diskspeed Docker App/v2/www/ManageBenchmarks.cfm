<CFPARAM name="FORM.Drive" default="">
<CFPARAM name="FORM.Import" default="">
<CFPARAM name="FORM.Keep" default="">

<CFIF FORM.Drive EQ "">
	<CFABORT>
</CFIF>

<CFSET KeepList=Replace(FORM.Keep,"AM,","AM|","ALL")>
<CFSET KeepList=Replace(KeepList,"PM,","PM|","ALL")>
<CFSET ImportList=Replace(FORM.Import,"AM,","AM|","ALL")>
<CFSET ImportList=Replace(ImportList,"PM,","PM|","ALL")>
<CFSET Key=ListFirst(FORM.Drive,"|")>
<CFSET PortNo=ListLast(FORM.Drive,"|")>

<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<!--- <cfdump var=#form#>
<cfoutput>KeepList: #KeepList#<br>ImportList: #ImportList#<br></cfoutput> --->

<CFSET BenchmarkDir="#PersistDir#/driveinfo/#HW[Key].Ports[PortNo].Config.SaveDir#/benchmark">
<CFDIRECTORY action="list" directory="#BenchmarkDir#" type="Dir" name="Dir">
<!--- Update DateLastModified with the benchmark scan date --->
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="read" file="#BenchmarkDir#/#Dir.Name[CR]#/datestamp.txt" variable="ScanDate">
	<CFSET QuerySetCell(Dir,"DateLastModified",ScanDate,CR)>
</CFLOOP>
<!--- <cfdump var=#dir#> --->

<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFSET CurrDate=DateFormat(Dir.DateLastModified[CR],"mmm d, yyyy") & " " & TimeFormat(Dir.DateLastModified[CR],"h:mm tt")>
	<CFIF ListFind(KeepList,CurrDate,"|") EQ 0>
		<CFOUTPUT>#CurrDate# - Del #Dir.Name[CR]#<br></CFOUTPUT>
		<CFDIRECTORY action="delete" directory="#BenchmarkDir#/#Dir.Name[CR]#" recurse="YES">
	</CFIF>
</CFLOOP>

<!--- Load in the saved bench history data --->
<CFFILE action="read" file="#BenchmarkDir#/BenchInfo.wddx" variable="BenchHistWDDX">
<cfwddx input="#BenchHistWDDX#" output="In" action="wddx2cfml">
<CFSET BenchHist=Duplicate(In.BenchHist)>
<CFSET BenchHistData=Duplicate(In.BenchData)>


<CFLOOP index="CR" from="1" to="#BenchHist.RecordCount#">
	<CFSET CurrDate=DateFormat(BenchHist.DateStamp[CR],"mmm d, yyyy") & " " & TimeFormat(BenchHist.DateStamp[CR],"h:mm tt")>
	<CFIF ListFindNoCase(ImportList,CurrDate,"|")>
		<CFOUTPUT>#CurrDate# - Import<br></CFOUTPUT>
		<CFSET BenchDir=BenchmarkDir & "/" & GetTickCount()>
		<CFDIRECTORY action="create" directory="#BenchDir#" mode="666">
		<CFQUERY name="SaveBenchData" dbtype="Query">
			SELECT *
			FROM BenchHistData
			WHERE BenchmarkID=#BenchHist.ID[CR]#
			ORDER BY Spot
		</CFQUERY>
		<CFSET Speed=QueryNew("id,Drive,DateStamp,Spot,Speed","integer,varchar,date,bigint,bigint")>
		<CFLOOP index="CF" from="1" to="#SaveBenchData.RecordCount#">
			<CFSET QueryAddRow(Speed)>
			<CFSET QuerySetCell(Speed,"id",CF)>
			<CFSET QuerySetCell(Speed,"Drive",HW[Key].Ports[PortNo].Config.SaveDir)>
			<CFSET QuerySetCell(Speed,"DateStamp",BenchHist.DateStamp[CR])>
			<CFSET QuerySetCell(Speed,"Spot",SaveBenchData.Spot[CF])>
			<CFSET QuerySetCell(Speed,"Speed",SaveBenchData.Speed[CF])>
		</CFLOOP>
		<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
			<CFFILE action="write" file="#BenchDir#/datestamp.txt" output="#BenchHist.DateStamp[CR]#" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/DriveLatency.txt" output="#BenchHist.DriveLatency[CR]#" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/RandomSeek.txt" output="#BenchHist.RandomSeek[CR]#" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/SequentialSeek.txt" output="#BenchHist.SequentialSeek[CR]#" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/valid.txt" output="" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/0000000000000000.txt" output="" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/submitted.txt" output="" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/restored.txt" output="" addnewline="NO" mode="666">
			<CFFILE action="write" file="#BenchDir#/version.txt" output="#Version#" addnewline="NO" mode="666">
			<CFSET json=SerializeJSON(Speed)>
			<CFFILE action="write" file="#BenchDir#/speed.json" output="#json#" addnewline="NO" mode="666">
		</cflock>
		<!--- <cfdump var=#savebenchdata#> --->
	</CFIF>
</CFLOOP>

<!--- Rebuild allspeed.json --->
<CFDIRECTORY action="list" directory="#BenchmarkDir#" type="Dir" name="Dir">

<CFSET allspeed=QueryNew("id,Drive,DateStamp,Spot,Speed","varchar,integer,date,bigint,bigint")>
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFIF FileExists("#BenchmarkDir#/#Dir.Name[CR]#/speed.json")>
		<CFFILE action="read" file="#BenchmarkDir#/#Dir.Name[CR]#/speed.json" variable="json">
		<CFSET benchspeed=DeserializeJSON(json,false)>
		<CFQUERY name="tmp" dbtype="Query">
			SELECT * FROM allspeed
			UNION
			SELECT * FROM benchspeed
		</CFQUERY>
		<CFSET allspeed=Duplicate(tmp)>
	</CFIF>
</CFLOOP>
<CFIF allspeed.RecordCount GT 0>
	<CFSET json=SerializeJSON(allspeed)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#BenchmarkDir#/allspeed.json" output="#json#" addnewline="NO" mode="666">
	</cflock>
<CFELSE>
	<CFIF FileExists("#BenchmarkDir#/allspeed.json")>
		<CFFILE action="Delete" file="#BenchmarkDir#/allspeed.json">
	</CFIF>
</CFIF>

<CFIF FileExists("#PersistDir#/driveinfo/DriveBenchmarks.txt")>
	<CFFILE action="delete" file="#PersistDir#/driveinfo/DriveBenchmarks.txt">
</CFIF>

<CFLOCATION URL="DispDrive.cfm?Drive=#URLEncodedFormat(FORM.Drive)#" addtoken="NO">

<!--- <cfdump var=#BenchHist#>
<cfdump var=#BenchData#> --->

https://jsfiddle.net/mnnf1x4a/3/

<cfsetting enablecfoutputonly="true" requesttimeout="0">

<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
<CFELSE>
	<CFABORT>
</CFIF>

<CFSET Key=Ref.DriveID[URL.Drive].Key>
<CFSET PortNo=Ref.DriveID[URL.Drive].PortNo>
<CFSET Drive=Duplicate(HW[Key].Ports[PortNo])>
<CFSET DriveID=URL.Drive>
<CFSET HeatDir=PersistDir & "/driveinfo/" & Drive.Config.SaveDir & "/surfacescan">

<CFIF FileExists("#SaveDir#/SpeedData.wddx")>
	<CFFILE action="read" file="#SaveDir#/SpeedData.wddx" variable="json">
	<cfwddx input="#json#" output="SpeedData" action="wddx2cfml">
<CFELSE>
	<CFSET SpeedData=QueryNew("GB,MBs,Duration","integer,integer,float")>
</CFIF>

<CFOUTPUT>
<script language="Javascript">
function o(txt)
{
	parent.document.getElementById('Info').innerHTML=txt;
}
</script>
</CFOUTPUT>

<CFOUTPUT>#HeatDir#<br></CFOUTPUT>

<CFSET EndSpot=Int(Drive.Attrib.Size.Bytes / Drive.OptimalBlockSize)>
<CFSET ChunkSize=Int(10000000000 / Drive.OptimalBlockSize)> <!--- How many blocks in 10 gig --->
<CFSET BlockCount=EndSpot / ChunkSize>
<CFSET BlocksToRead=1000>
<CFIF Int(BlockCount) EQ BlockCount>
	<CFSET EndScan=0>
<CFELSE>
	<CFSET BlockCount=Int(BlockCount)>
	<CFSET EndScan=1>
</CFIF>
<cfoutput>
EndSpot: [#EndSpot#]<br>
ChunkSize: [#ChunkSize#]<br>
BlockCount: [#BlockCount#]<br>
EndScan: [#EndScan#]<br>
</cfoutput>

<CFSET Script="echo ""1"" > #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10) &
			  "BlockSize=#Drive.OptimalBlockSize#" & Chr(10) &
			  "BlocksToRead=#BlockstoRead#" & Chr(10) &
			  "SaveDir='#SaveDir#'" & Chr(10) &
			  "HeatDir='#HeatDir#'" & Chr(10) &
			  "Device='#Drive.DriveID#'" & Chr(10) &
			  "function CkAbort {" & Chr(10) &
			  "  if [ -e ""/tmp/DiskSpeedTmp/KillHeat.txt"" ];then" & Chr(10) &
			  "    rm #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10) &
			  "    exit" & Chr(10) &
			  "  fi" & Chr(10) &
			  "}" & Chr(10) &
			  "function Bench {" & Chr(10) &
			  "  echo $2" & Chr(10) &
			  "  dd if=/dev/$Device of=/dev/null bs=$BlockSize skip=$1 count=$BlocksToRead iflag=direct status=progress conv=noerror 2> $SaveDir/$DriveID_$2.spot &" & Chr(10) &
			  "  PID=$!" & Chr(10) &
			  "  sleep 5" & Chr(10) &
			  "  kill $PID" & Chr(10) &
			  "  sleep 1" & Chr(10) &
			  "  mv $SaveDir/$DriveID_$2.spot $HeatDir/$2.spot" & Chr(10) &
			  "  chmod 666 $HeatDir/$2.spot" & Chr(10) &
			  "}" & Chr(10) &
			  "dd if=/dev/$Device of=/dev/null bs=$BlockSize skip=0 count=1 iflag=direct" & Chr(10)>

<CFSET Script2="">

<CFLOOP index="i" from="1" to="#EndSpot#" Step="#ChunkSize#">
	<CFSET Start=(i-1)>
	<CFSET FN=Replace(RJustify(i-1,Len(EndSpot)+1)," ","0","ALL")>
	<CFSET Script=Script & "Bench #Start# #FN#" & Chr(10) &
						   "CkAbort" & Chr(10)>
	<CFIF Len(Script) GT 102400>
		<CFSET Script2=Script2 & Script>
		<CFSET Script="">
	</CFIF>
</CFLOOP>

<CFSET Script=Script2 & Script>
<CFSET Script2="">


<!---
<CFIF EndScan EQ 1>
	<CFSET Start=BlockCount*ChunkSize>
	<CFSET FN=Replace(RJustify(BlockCount,Len(BlockCount)+1)," ","0","ALL") & ".scan">
	<CFSET Script=Script & "dd if=/dev/#Drive.DriveID# of=/dev/null bs=#Drive.OptimalBlockSize# skip=#Start# iflag=direct status=progress conv=noerror 2> #SaveDir#/#Drive.DriveID#_#FN#" & Chr(10) &
						   "mv #SaveDir#/#Drive.DriveID#_#FN# #HeatDir#/#FN#" & Chr(10) &
						   "chmod 666 #HeatDir#/#FN#" & Chr(10) &
						   "if [ -e ""/tmp/DiskSpeedTmp/KillHeat.txt"" ];then" & Chr(10) &
						   "	rm #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10) &
						   "	exit" & Chr(10) &
						   "fi" & Chr(10)>
<CFELSE>
	<CFSET BlockCount=BlockCount-1>
	<CFSET Start=BlockCount*ChunkSize>
	<CFSET Script=Script & "dd if=/dev/#Drive.DriveID# of=/dev/null bs=#Drive.OptimalBlockSize# skip=#Start# iflag=direct status=progress conv=noerror 2> #SaveDir#/#Drive.DriveID#_#FN#" & Chr(10) &
						   "mv #SaveDir#/#Drive.DriveID#_#FN# #HeatDir#/#FN#" & Chr(10) &
						   "chmod 666 #HeatDir#/#FN#" & Chr(10) &
						   "if [ -e ""/tmp/DiskSpeedTmp/KillHeat.txt"" ];then" & Chr(10) &
						   "	rm #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10) &
						   "	exit" & Chr(10) &
						   "fi" & Chr(10)>
</CFIF>

<CFLOOP index="i" from="1" to="#BlockCount#">
	<CFSET Start=(i-1)*ChunkSize>
	<CFSET FN=Replace(RJustify(i-1,Len(BlockCount)+1)," ","0","ALL") & ".scan">
	<CFSET Script=Script & "dd if=/dev/#Drive.DriveID# of=/dev/null bs=#Drive.OptimalBlockSize# skip=#Start# count=#ChunkSize# iflag=direct status=progress conv=noerror 2> #SaveDir#/#Drive.DriveID#_#FN#" & Chr(10) &
						   "mv #SaveDir#/#Drive.DriveID#_#FN# #HeatDir#/#FN#" & Chr(10) &
						   "chmod 666 #HeatDir#/#FN#" & Chr(10) &
						   "if [ -e ""/tmp/DiskSpeedTmp/KillHeat.txt"" ];then" & Chr(10) &
						   "	rm #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10) &
						   "	exit" & Chr(10) &
						   "fi" & Chr(10)>
</CFLOOP>
--->

<CFSET Script=Script & "rm #SaveDir#/heat_#Drive.DriveID#.txt" & Chr(10)>

<CFIF DirectoryExists(HeatDir) EQ "NO">
	<CFDIRECTORY action="create" directory="#HeatDir#" mode="666">
</CFIF>
<CFFILE action="write" file="#HeatDir#/heat_#Drive.DriveID#.sh" output="#Script#" addnewline="NO" mode="766">

<xcfexecute name="#HeatDir#/heat_#Drive.DriveID#.sh" />


<CFOUTPUT><pre>#Script#</pre></CFOUTPUT>

<cfdump var=#drive#>
<cfabort>


<CFLOOP index="GB" from="0" to="#EndSpot#" step="#BlockCount#">
	<CFSET Per=GB / EndSpot / 0.01>
	<CFQUERY name="ChkBlock" dbtype="Query">
		SELECT * FROM SpeedData WHERE GB=#GB#
	</CFQUERY>
	<CFSET FN=Replace(RJustify(GB,L)," ","0","ALL") & ".txt">
	<CFIF ChkBlock.RecordCount EQ 0>
		<CFOUTPUT><script>o('Reading drive... #Trim(NumberFormat(GB,"999,999"))# (#Trim(NumberFormat(Per,"999.9"))#%)');</script></CFOUTPUT><CFFLUSH>
		<CFSET Script="dd if=/dev/#DriveID# of=/dev/null bs=1GB skip=#GB# count=5 iflag=direct status=progress conv=noerror 2>#SaveDir#/#FN##Chr(10)#">
		<CFFILE action="write" file="/tmp/SurfaceScan.sh" output="#Script#" addnewline="NO" mode="777">
		<cfexecute name="/tmp/SurfaceScan.sh" timeout="300" />
		<CFSET SpeedInfo=ParseSurfaceScan("#SaveDir#/#FN#")>
		<CFFILE action="Delete" file="#SaveDir#/#FN#">
		<CFLOOP index="i" from="1" to="#ArrayLen(SpeedInfo)#">
			<CFSET QueryAddRow(SpeedData)>
			<CFSET QuerySetCell(SpeedData,"GB",GB + i - 1)>
			<CFSET QuerySetCell(SpeedData,"MBs",Val(ListFirst(SpeedInfo[i][1],"|")))>
			<CFSET QuerySetCell(SpeedData,"Duration",Val(ListLast(SpeedInfo[i][2],"|")))>
		</CFLOOP>
		<cfwddx input="#SpeedData#" output="json" action="cfml2wddx">
		<CFFILE action="write" file="#SaveDir#/SpeedData.wddx" output="#json#" mode="666" addnewline="NO">
	</CFIF>
</CFLOOP>

<cfdump var=#drive#>
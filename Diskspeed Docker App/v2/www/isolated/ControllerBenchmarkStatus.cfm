<CFSET Result=ArrayNew(2)>
<CFSET Results=ArrayNew(1)>
<CFSET ArraySet(Results,1,URL.Drives,"")>
<CFLOOP index="x" from="1" to="#URL.Drives#">
	<CFLOOP index="y" from="1" to="#URL.Drives#">
		<CFSET Result[x][y]=0>
	</CFLOOP>
</CFLOOP>

<CFSET Status="Starting...">
<CFIF FileExists("/tmp/DiskSpeed/controller_#URL.Controller#.txt")>
	<CFFILE action="read" file="/tmp/DiskSpeed/controller_#URL.Controller#.txt" variable="Status">
</CFIF>

<CFLOOP index="i" from="1" to="#URL.Drives#">
	<CFIF FileExists("/tmp/DiskSpeed/controller_#URL.Controller#_#i#_0.txt")>
		<CFLOOP index="q" from="1" to="#i#">
			<CFFILE action="read" file="/tmp/DiskSpeed/controller_#URL.Controller#_#i#_#q#.txt" variable="SpeedData">
			<CFSET SpeedData=Trim(ListLast(ListLast(SpeedData,Chr(10))))>
			<CFSET Speed=ListFirst(SpeedData," ")>
			<CFSET SpeedInd=ListLast(SpeedData," ")>
			<CFIF SpeedInd EQ "GB/s">
				<CFSET Speed=Speed * 1000>
			<CFELSEIF SpeedInd NEQ "MB/s">
				<CFSET Speed=1>
			</CFIF>
			<CFSET Result[i][q]=Speed>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<CFLOOP index="x" from="1" to="#URL.Drives#">
	<CFLOOP index="y" from="1" to="#URL.Drives#">
		<CFSET Results[y]=ListAppend(Results[y],Result[x][y])>
	</CFLOOP>
</CFLOOP>

<CFSET Results[ArrayLen(Results)+1]=Status>
<CFSET ResultsJSON=SerializeJSON(Results)>

<CFIF Status EQ "Finished">
	<CFIF DirectoryExists("#PersistDir#/controller/#URL.Controller#") EQ "NO">
		<CFDIRECTORY action="create" directory="#PersistDir#/controller/#URL.Controller#" mode="666">
	</CFIF>
	<CFFILE action="write" file="#PersistDir#/controller/#URL.Controller#/benchmark.json" output="#ResultsJSON#" addnewline="NO" mode="666">
	<CFDIRECTORY action="list" directory="/tmp/DiskSpeed" filter="controller_#URL.Controller#*.*" type="File" name="Dir">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="delete" file="/tmp/DiskSpeed/#Dir.Name[CR]#">
	</CFLOOP>
</CFIF>

<cfcontent type="text/json" reset="true">
<CFOUTPUT>#ResultsJSON#</CFOUTPUT>

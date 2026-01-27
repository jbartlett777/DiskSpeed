<CFSET RootDir=Replace(ExpandPath("."),"\","/","ALL")>
<CFSET ParentDir=ListDeleteAt(RootDir,ListLen(RootDir,"/"),"/")>
<CFSET DSN="mysql">
<CFSET Highcharts="/Highcharts-9.0.0">
<CFSET HeatMapX=400>
<CFSET HeatMapY=100>

<CFIF DirectoryExists("#RootDir#/Cache") EQ "NO">
	<CFDIRECTORY action="Create" directory="#RootDir#/Cache" mode="655">
</CFIF>

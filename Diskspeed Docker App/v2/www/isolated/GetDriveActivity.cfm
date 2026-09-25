<CFSET Out=StructNew()>
<CFIF FileExists("/var/local/emhttp/diskload.ini")>
	<CFFILE action="read" file="/var/local/emhttp/diskload.ini" variable="ReadData">
	<CFLOOP index="CurrLine" list="#ReadData#" delimiters="#Chr(10)#">
		<CFSET Drive=ListFirst(CurrLine,"=")>
		<CFSET DriveActivity=ListFirst(ListLast(CurrLine,"=")," ")>
		<CFSET Out[Drive]=DriveActivity>
	</CFLOOP>
</CFIF>

<CFSET OutJS=SerializeJSON(Out)>

<cfcontent type="text/json" reset="true">
<cfoutput>#outjs#</cfoutput>
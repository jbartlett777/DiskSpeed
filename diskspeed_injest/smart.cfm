<CFSET JSONDir="C:\inetpub\strangejourney.net\SMARTJson">

<CFPARAM name="FORM.ZipFile" default="">
<CFPARAM name="URL.DelIDs" default="">
<CFPARAM name="URL.h" default="">

<CFIF URL.DelIDs NEQ "">
	<CFIF Hash(URL.DelIDs) NEQ URL.h>
		<CFOUTPUT>error - invalid request</CFOUTPUT>
	<CFELSE>
		<CFOUTPUT>Done. #ListLen(URL.DelIDs)# drives removed.</CFOUTPUT>
		<CFFILE action="write" file="#JSONDir#/del_#URL.h#.txt" output="#URL.DelIDs#" addnewline="No" mode="666">
	</CFIF>
	<CFFLUSH>
	<CFABORT>
</CFIF>

<cflock name="ScanControllers" type="exclusive" throwontimeout="false" timeout="5">
	<CFSET X=0>
	<CFSET FN="#JSONDir#\" & DateFormat(Now(),"yyyy-mm-dd") & "_" & TimeFormat(Now(),"HH-mm-ss") & ".zip">

	<CFIF FORM.ZipFile NEQ "">
		<CFTRY>
			<CFFILE action="upload" destination="#FN#" mode="666" filefield="FORM.ZipFile" nameconflict="makeunique" accept="application/zip">
		<CFCATCH Type="Any">
			<CFOUTPUT>Fail - #CFCATCH.Message#</CFOUTPUT><CFABORT>
		</CFCATCH>
		</CFTRY>
	</CFIF>
</cflock>

<CFOUTPUT>Ok</CFOUTPUT>

<cfsetting enablecfoutputonly="Yes">

<cfapplication name="HDDB" clientmanagement="false" applicationtimeout="#CreateTimeSpan(1,0,0,0)#" setclientcookies="false" setdomaincookies="false" sessionmanagement="false">

<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="30">
	<CFPARAM name="Application.Key" default="#GenerateSecretKey('AES')#">
	<CFSET EncryptionKey=Application.Key>
</cflock>

<CFINCLUDE template="environment.cfm">
<CFINCLUDE template="CustomFunctions.cfm">

<CFLOCK scope="Application" type="exclusive" timeout="2">
	<CFPARAM name="Application.EditStyles" default="0">
	<CFSET EditStyles=Application.EditStyles>
</CFLOCK>
<CFSET EditStyles=0>
<CFIF EditStyles EQ 0>
	<!--- Check to see if the styles need to have cache buster attribute set set --->
	<CFSET CB=DateTimeFormat(Now(),"yyyymmddHHmmss")>
	<CFDIRECTORY action="List" directory="#RootDir#/Templates" name="Dir" type="File" filter="*.html">
	<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
		<CFFILE action="Read" file="#Dir.Directory[CR]#/#Dir.Name[CR]#" variable="HTML">
		<CFSET Match=REMatchNoCase("<link\b(?=[^>]*\brel\s*=\s*[""']stylesheet[""'])(?=[^>]*\bhref\s*=\s*[""'][^""']*\.css[""'])[^>]*>",HTML)>
		<CFIF ArrayLen(Match) EQ 0>
			<CFBREAK> <!--- Stop if this process has already been done --->
		</CFIF>
		<CFLOOP index="i" from="1" to="#ArrayLen(Match)#">
			<CFSET HTML=Replace(HTML,Match[i],Replace(Match[i],"css""","css?cb=#CB#"""))>
		</CFLOOP>

		<!--- Check for default both background color and remove --->
		<CFSET Match=REMatchNoCase("body[\w\d\s\W\D\S]*?background:\svar\(--dl-color-gray-white\);[\w\d\s\W\D\S]*?}",HTML)>
		<CFLOOP index="i" from="1" to="#ArrayLen(Match)#">
			<CFSET HTML=Replace(HTML,Match[i],Replace(Match[i],"background: var(--dl-color-gray-white);",""))>
		</CFLOOP>

		<CFFILE action="write" file="#Dir.Directory[CR]#/#Dir.Name[CR]#" output="#HTML#" addnewline="NO" mode="655">
	</CFLOOP>

	<!--- Flag that the HTML files have been updated --->
	<CFLOCK scope="Application" type="exclusive" timeout="2">
		<CFSET Application.EditStyles=1>
	</CFLOCK>
</CFIF>

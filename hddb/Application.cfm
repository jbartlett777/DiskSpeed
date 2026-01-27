<cfsetting enablecfoutputonly="Yes">

<cfapplication name="HDDB" clientmanagement="false" applicationtimeout="#CreateTimeSpan(0,12,0,0)#" setclientcookies="false" setdomaincookies="false" sessionmanagement="false">

<cflock type="exclusive" scope="Application" throwontimeout="false" timeout="30">
	<CFPARAM name="Application.Key" default="#GenerateSecretKey('AES')#">
	<CFSET EncryptionKey=Application.Key>
</cflock>

<CFINCLUDE template="environment.cfm">
<CFINCLUDE template="CustomFunctions.cfm">

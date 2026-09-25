<CFPARAM name="variables.StartTick" default="#GetTickCount()#">

<cflock type="exclusive" scope="Session" throwontimeout="true" timeout="30">
	<CFSET Session.RequestID=StartTick>
	<CFSET SessionID=StartTick>
</cflock>
<CFINCLUDE Template="RemoveTempFiles.cfm">

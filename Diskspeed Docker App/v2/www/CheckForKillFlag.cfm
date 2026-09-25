<CFPARAM name="variables.SessionID" default="">
<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFPARAM name="Session.RequestID" default="">
	<CFIF Session.RequestID NEQ SessionID>
		<CFOUTPUT>
		This application was opened in a different browser window or another page displayed, aborting this process.
		</CFOUTPUT><CFFLUSH><CFABORT>
	</CFIF>
</cflock>

<CFOUTPUT>
<CFIF CGI.script_name NEQ "/ScanControllers.cfm">
	<img src="images/home.png" height="24">
</CFIF>
<span class="Size24"><span class="Bold">DiskSpeed</span> - Disk Diagnostics & Reporting tool</span><br>
<span class="Size14 Red">Version: #AppVer#</span><br>
<CFIF StrangeJourney NEQ "https://strangejourney.net" AND DiskSpeedDeveloper EQ 1>
	Host Override: #StrangeJourney#<br>
</CFIF>
<br>
</CFOUTPUT>

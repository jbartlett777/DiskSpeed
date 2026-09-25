<CFPARAM name="NoFlush" default="0">

<CFOUTPUT>#TS()# Fetching Drive Platter Information<br></CFOUTPUT><CFIF NOT NoFlush><CFFLUSH></CFIF>

<CFSET SendVendor="">
<CFSET SendModel="">
<CFSET Processed="">
<CFLOOP index="CurrItem" list="#NeedPlatter#" delimiters="~">
	<CFSET Key=ListFirst(CurrItem,"|")>
	<CFSET PortNo=ListLast(CurrItem,"|")>
	<CFSET Drive=HW[Key].Ports[PortNo]>
	<CFIF ListFindNocase(Processed,"#Drive.Attrib.Vendor#|#Drive.Attrib.Model#") EQ 0>
		<CFSET Processed=ListAppend(Processed,"#Drive.Attrib.Vendor#|#Drive.Attrib.Model#")>
		<CFSET SendVendor=ListAppend(SendVendor,ReturnRegExAsString("[A-Za-z0-9 -]*",Drive.Attrib.Vendor))>
		<CFSET SendModel=ListAppend(SendModel,ReturnRegExAsString("[A-Za-z0-9 -]*",Drive.Attrib.Model))>
	</CFIF>
</CFLOOP>

<CFSET h=LCase(Hash(SendVendor & "|" & SendModel))>
<CFSET DriveURL="#StrangeJourney#/diskspeed/GetPlatterInfo.cfm?vendor=" & URLEncodedFormat(SendVendor) & "&model=" & URLEncodedFormat(SendModel) & "&h=#H#">
<!--- <CFOUTPUT>URL: #DriveURL#<br></CFOUTPUT> --->
<CFHTTP URL="#DriveURL#" />

<CFSET json=SerializeJSON(CFHTTP)>
<CFFILE action="write" file="#PersistDir#/GetPlatterHTTPResult.json" output="#json#" addnewline="NO" mode="666">
<CFIF CFHTTP.Status_Code EQ 200>
	<CFIF StripCRLF(Trim(CFHTTP.FileContent)) EQ "">
		<CFSET Info=ArrayNew(1)>
	<CFELSE>
		<CFSET Info=DeserializeJSON(CFHTTP.FileContent)>
	</CFIF>
	<CFSET Reported="">
	<CFTRY>
		<CFLOOP index="i" from="1" to="#ArrayLen(Info)#">
			<CFSET UpdateList=Ref.Vendor[Info[i].Vendor][Info[i].Model]>
			<CFLOOP index="CurrDrive" list="#UpdateList#">
				<CFSET Key=ListFirst(CurrDrive,"|")>
				<CFSET PortNo=ListLast(CurrDrive,"|")>
				<CFSET HW[Key].Ports[PortNo].Attrib.PlatterCnt=Info[i].PlatterCnt>
				<CFSET HW[Key].Ports[PortNo].Attrib.HeadCnt=Info[i].HeadCnt>
				<CFSET HW[Key].Ports[PortNo].Attrib.ShortStroked=Info[i].ShortStroked>
			</CFLOOP>
		</CFLOOP>
	<CFCATCH Type="Any">
		<CFOUTPUT>#TS()# There was an error fetching the drive platter information - this issue is typically resolved by rescanning your controllers again<br></CFOUTPUT><CFIF NOT NoFlush><CFFLUSH></CFIF>
	</CFCATCH>
	</CFTRY>
	<!--- <cfdump var=#info# --->
<CFELSE>
	<CFOUTPUT>#TS()# There was an error fetching the drive platter information<br></CFOUTPUT><CFIF NOT NoFlush><CFFLUSH></CFIF>
</CFIF>
<!--- <cfdump var=#cfhttp#>
<cfdump var=#Drive#> --->

<!---
<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
 --->

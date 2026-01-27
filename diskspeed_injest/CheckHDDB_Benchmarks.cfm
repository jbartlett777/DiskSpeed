<CFPARAM name="URL.Drives" default="">
<CFPARAM name="FORM.Drives" default="#URL.Drives#">
<CFPARAM name="URL.h" default="">
<CFPARAM name="FORM.h" default="#URL.h#">

<CFIF FORM.h NEQ Hash(FORM.Drives & URLEncodedFormat(FORM.Drives))>
	<CFOUTPUT>Wut</CFOUTPUT><CFABORT>
</CFIF>
<CFIF Find(";",FORM.Drives)>
	<CFOUTPUT>Wut</CFOUTPUT><CFABORT>
</CFIF>

<CFSET CheckHDDB=Duplicate(DeserializeJSON(FORM.Drives))>

<CFSET Ret=ArrayNew(1)>
<CFLOOP index="i" from="1" to="#ArrayLen(CheckHDDB)#">
	<CFQUERY name="HDDB" datasource="mysql">
		SELECT *
		FROM DiskSpeed.Models
		WHERE VendorID=(SELECT ID FROM DiskSpeed.Vendors WHERE Vendor='#CheckHDDB[i].V#')
		  AND Model='#CheckHDDB[i].M#'
		  AND Revision='#CheckHDDB[i].R#'
	</CFQUERY>
	<CFSET Ret[i]=HDDB.RecordCount>
</CFLOOP>

<CFSET ResultsJSON=SerializeJSON(Ret)>

<cfcontent type="text/json" reset="true">
<CFOUTPUT>#ResultsJSON#</CFOUTPUT>
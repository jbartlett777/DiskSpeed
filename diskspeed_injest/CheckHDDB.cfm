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
<CFSET C=Chr(10)>
<CFSET Ret=ArrayNew(1)>
<CFLOOP index="i" from="1" to="#ArrayLen(CheckHDDB)#">
	<CFTRY>
		<CFQUERY name="HDDB" datasource="mysql">
			SELECT *
			FROM DiskSpeed.Models
			WHERE VendorID IN (SELECT ID FROM DiskSpeed.Vendors WHERE Vendor='#CheckHDDB[i].V#') -- This should just be one row
			  AND Model='#CheckHDDB[i].M#'
			  AND Revision='#CheckHDDB[i].R#'
		</CFQUERY>
		<CFSET Ret[i]=HDDB.RecordCount>
	<CFCATCH Type="Any">
		<CFFILE action="Append" file="C:\inetpub\strangejourney.net\www\diskspeed\ErrorSQL.txt" output="Drives: [#URL.Drives#][#FORM.Drives#]#C#H: [#URL.H#][#FORM.H#]#C#SELECT *#C#FROM DiskSpeed.Models#C#WHERE VendorID IN (SELECT ID FROM DiskSpeed.Vendors WHERE Vendor='#CheckHDDB[i].V#') -- This should just be one row#C#  AND Model='#CheckHDDB[i].M#'#C#  AND Revision='#CheckHDDB[i].R#'#C#================" addnewline="NO">
		<CFSET Ret[i]=0>
	</CFCATCH>
	</CFTRY>
</CFLOOP>

<CFSET ResultsJSON=SerializeJSON(Ret)>

<cfcontent type="text/json" reset="true">
<CFOUTPUT>#ResultsJSON#</CFOUTPUT>
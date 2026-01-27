<!--- Load in TeleportHQ page --->
<CFFILE action="read" file="#RootDir#/Templates/brand-images.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">


<!--- Populate Model Links --->
<CFSET ModelRegEx="<a[\w\d\s]+?href=""https:\/\/BrandImages.cfm\?Model=\[x\]""[\w\d\s\W\D\S]+?<\/a>">
<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" name="Vendors" type="Dir" sort="Name">

<CFSET Links="">
<CFLOOP index="CR" from="1" to="#Vendors.RecordCount#">
	<CFSET Links=Links & "<a href=""javascript:void(0);"" onClick=""ViewVendor('#EncodeForJavascript(Vendors.Name[CR])#')"" class=""brand-images-link3"">#EncodeForHTML(Vendors.Name[CR])#</a><br>">
</CFLOOP>
<CFSET HTML=REReplaceNoCase(HTML,ModelRegEx,Links)>

<!--- Add Javascript --->
<CFSAVECONTENT variable="JS">
<CFOUTPUT>
<script>
function ViewVendor(vendor) {
	document.getElementById('ModelFrame').src='BrandImages2.cfm?Vendor='+vendor;
}
</script>
</CFOUTPUT>
</CFSAVECONTENT>

<CFSET HTML=ReplaceNoCase(HTML,"</head>","#JS#</head>")>

<CFSET HTML=ReplaceNoCase(HTML,"https://www.johnwbartlett.com","BrandImages2.cfm")>

<CFOUTPUT>#HTML#</CFOUTPUT>
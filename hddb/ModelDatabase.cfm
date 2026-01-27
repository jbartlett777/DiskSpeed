<CFPARAM name="URL.Vendor" default="">
<CFPARAM name="URL.Model" default="">

<!--- Load in TeleportHQ page --->
<CFFILE action="read" file="#RootDir#/Templates/model-database.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">

<CFSET HTML=ReplaceNoCase(HTML,"https://www.johnwbartlett.com","ModelDatabase2.cfm")>

<CFQUERY name="Vendors" datasource="#DSN#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>

<CFSET ModelRegEx="<a[\w\d\s]+?href=""https:\/\/BrandImages.cfm\?Model=\[x\]""[\w\d\s\W\D\S]+?<\/a>">

<CFSET Links="">
<CFLOOP index="CR" from="1" to="#Vendors.RecordCount#">
	<CFSET Links=Links & "<a href=""javascript:void(0);"" onClick=""ViewVendor('#EncodeForJavascript(Vendors.Vendor[CR])#')"" class=""brand-images-link3"">#EncodeForHTML(Vendors.Vendor[CR])#</a><br>">
</CFLOOP>
<CFSET HTML=REReplaceNoCase(HTML,ModelRegEx,Links)>

<!--- Add Javascript --->
<CFSAVECONTENT variable="JS">
<CFOUTPUT>
<script>
function ViewVendor(vendor) {
	document.getElementById('ModelFrame').src='ModelDatabase2.cfm?Vendor='+vendor;
}
</script>
</CFOUTPUT>
</CFSAVECONTENT>

<CFSET HTML=ReplaceNoCase(HTML,"</head>","#JS#</head>")>

<CFIF URL.Vendor NEQ "" AND URL.Model NEQ "">
	<CFSET HTML=Replace(HTML,"src=""ModelDatabase2.cfm""","src=""ModelDatabase2.cfm?Vendor=#EncodeForURL(URL.Vendor)#&Model=#EncodeForURL(URL.Model)#""")>
</CFIF>

<CFOUTPUT>#HTML#</CFOUTPUT>

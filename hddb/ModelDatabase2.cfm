
<CFPARAM name="URL.Vendor" default="">
<CFPARAM name="URL.Model" default="">

<CFIF URL.Vendor NEQ "" AND URL.Model NEQ "">
	<CFINCLUDE TEMPLATE="Drives/DispModelInfo.cfm">
	<cfexit>
</CFIF>

<CFFILE action="read" file="#RootDir#/Templates/model-database-2.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">
<CFSET HTML=Replace(HTML,"background-color: var(--dl-color-gray-white);","")>
<CFSET HTML=Replace(HTML,"model-database2-container5","")>

<CFFILE action="read" file="#RootDir#/Templates/model-database-2.css" variable="CSS">
<CFIF Find("width: 70vw;",CSS) or FIND("background-color: ##000000;",CSS)>
	<CFSET CSS=REReplaceNoCase(CSS,"width: 70vw;\s+?min-height: 70vh;","")>
	<CFSET CSS=Replace(CSS,"background-color: ##000000;","")>
	<CFFILE action="write" file="#RootDir#/Templates/model-database-2.css" output="#CSS#" addnewline="NO" mode="655">
</CFIF>

<CFQUERY name="Vendors" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>

<!--- Validate Vendor --->
<CFSET URL.Vendor=Replace(URL.Vendor,"x20"," ","ALL")>
<CFSET URL.Vendor=Replace(URL.Vendor,"x2D","-","ALL")>

<CFQUERY name="ChkVendor" dbtype="Query">
	SELECT *
	FROM Vendors
	WHERE Vendor=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#URL.Vendor#">
</CFQUERY>
<CFIF ChkVendor.RecordCount EQ 0>
	<CFSET URL.Vendor=Vendors.Vendor[1]>
	<CFQUERY name="ChkVendor" dbtype="Query">
		SELECT *
		FROM Vendors
		WHERE Vendor=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#URL.Vendor#">
	</CFQUERY>
</CFIF>

<CFQUERY name="Drives" datasource="MySQL">
	SELECT m.Model, COUNT(b.ModelID) as BenchmarkCount
	FROM DiskSpeed.Models m
	INNER JOIN DiskSpeed.Vendors v ON (m.VendorID=v.ID)
	LEFT JOIN DiskSpeed.BenchmarkID b ON (m.ModelID=b.ModelID)
	WHERE v.Vendor='#URL.Vendor#'
		AND m.Model <> ''
	GROUP BY m.Model
	ORDER BY m.Model
</CFQUERY>

<CFSET RevionBlock="<div id=""VendorDiv[\w\d\s\W\D\S]+?</div>">

<CFSET HTML=Replace(HTML,"[Vendor]",EncodeForHTML(ChkVendor.Vendor))>
<CFSET HTML=Replace(HTML,"[ModelCount]",Drives.RecordCount)>

<CFSAVECONTENT variable="Links">
<CFOUTPUT>
<CFLOOP index="CR" from="1" to="#Drives.RecordCount#">
	<CFIF Drives.BenchmarkCount[CR] EQ 0>
		<div id="VendorDiv" class="VendorDiv">
			<p class="ModelRevisionList"><a href="ModelDatabase2.cfm?Vendor=#EncodeForURL(URL.Vendor)#&Model=#EncodeForURL(Drives.Model[CR])#">#EncodeForHTML(Drives.Model[CR])#</a></p>
		</div>
	<CFELSE>
		<div id="VendorDiv" class="VendorDiv">
			<p class="ModelRevisionList Bold"><a href="ModelDatabase2.cfm?Vendor=#EncodeForURL(URL.Vendor)#&Model=#EncodeForURL(Drives.Model[CR])#">#EncodeForHTML(Drives.Model[CR])#</a></p>
		</div>
	</CFIF>
</CFLOOP>
</CFOUTPUT>
</CFSAVECONTENT>

<CFSET HTML=REReplaceNoCase(HTML,RevionBlock,Links)>

<CFOUTPUT>#HTML#</CFOUTPUT>

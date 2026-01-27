<CFTRY>
<CFQUERY name="AllVendors" datasource="mysql">
	SELECT Vendor, upper(Vendor) as Vendor2
	FROM DiskSpeed.Vendors
	WHERE Vendor<>''
</CFQUERY>

<cfwddx input="#AllVendors#" output="AllVendorsWDDX" action="cfml2wddx">
<cfcontent type="text/plain" reset="true">
<CFOUTPUT>#AllVendorsWDDX#</CFOUTPUT>

<CFCATCH Type="Any">
	<cfcontent type="text/plain" reset="true">
	<CFOUTPUT></CFOUTPUT>
</CFCATCH>
</CFTRY>

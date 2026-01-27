<CFQUERY name="Vendors" datasource="#DSN#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>

<CFSET QueryAddRow(Vendors)>
<CFSET QuerySetCell(Vendors,"Vendor","Unknown")>
<CFSET QuerySetCell(Vendors,"Cnt",1)>

<CFPARAM name="URL.Vendor" default="#Vendors.Vendor[1]#">
<CFPARAM name="URL.Model" default="">

<CFIF Find(".",URL.Vendor)>
	<CFABORT>
</CFIF>

<CFQUERY name="CheckVendor" dbtype="QUERY">
	SELECT *
	FROM Vendors
	WHERE Vendor='#URL.Vendor#'
</CFQUERY>
<CFIF CheckVendor.RecordCount EQ 0>
	<CFSET URL.Vendor=Vendors.Vendor[1]>
</CFIF>

<CFOUTPUT>
<table cellpadding="0" cellspacing="0" cellpadding="0" width="100%">
	<tr>
		<td valign="top" class="NOBR" width="1">
			<!-- <div style="overflow-y:scroll;"> -->
			<!--- List Vendors --->
			</CFOUTPUT>
			<CFLOOP index="CR" from="1" to="#Vendors.RecordCount#">
				<CFSET TextColor=" White">
				<CFIF Vendors.Vendor[CR] EQ URL.Vendor>
					<CFSET TextColor=" Yellow">
				</CFIF>
				<CFOUTPUT><a href="index.cfm?View=Drives&Vendor=#Vendors.Vendor[CR]#" class="Arial Bold TextBorder Size24 NoLink#TextColor#">#Vendors.Vendor[CR]#</a><br/>#Chr(10)#</CFOUTPUT>
			</CFLOOP>
			<CFOUTPUT>
			<!-- </div> -->
		</td>
		<td width="1">&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td valign="top">
			</CFOUTPUT>
			<!--- Fetch all models with benchmarks --->
			<CFQUERY name="Drives" datasource="#DSN#">
				SELECT m.Model, COUNT(b.ModelID) as BenchmarkCount
				FROM DiskSpeed.Models m
				INNER JOIN DiskSpeed.Vendors v ON (m.VendorID=v.ID)
                LEFT JOIN DiskSpeed.BenchmarkID b ON (m.ModelID=b.ModelID)
				WHERE v.Vendor='#URL.Vendor#'
				  AND m.Model <> ''
				GROUP BY m.Model
				ORDER BY m.Model
			</CFQUERY>
			<CFIF URL.Model NEQ "">
				<CFQUERY name="Chk" dbtype="Query">
					SELECT *
					FROM Drives
					WHERE Model='#URL.Model#'
				</CFQUERY>
				<CFIF Chk.RecordCount EQ 0>
					<CFSET URL.Model="">
				</CFIF>
			</CFIF>
			<CFIF URL.Model EQ "">
				<!--- Display all models --->
				<CFOUTPUT>
				<span class="Arial White Size24">#Drives.RecordCount# drive model<CFIF Drives.RecordCount NEQ 1>s</CFIF> found</span><br/>
				<br/>
				<table border="0" cellpadding="0" cellspacing="0" width="100%">
					<tr>
						<td>
							<div class="Columns Arial White Size14 NOBR">
							</CFOUTPUT>
							<CFLOOP Index="CR" from="1" to="#Drives.RecordCount#">
								<CFIF Drives.BenchmarkCount[CR] EQ 0>
									<CFOUTPUT><a href="index.cfm?View=Drives&Vendor=#URL.Vendor#&Model=#Drives.Model[CR]#" class="Arial LightGrey Size14 NoLink">#Drives.Model[CR]#</a><br/></CFOUTPUT>
								<CFELSE>
									<CFOUTPUT><a href="index.cfm?View=Drives&Vendor=#URL.Vendor#&Model=#Drives.Model[CR]#" class="Arial White Size14 Bold NoLink">#Drives.Model[CR]#</a><br/></CFOUTPUT>
								</CFIF>
							</CFLOOP>
							<CFOUTPUT>
							</div>
						</td>
					</tr>
				</table>
				<br>
				<span class="Arial White Size14">
				<span class="Size18">Key:<br></span>
				<span class="Bold">Bold</span>: Benchmark data exists<br>
				<span class="LightGrey">Unbold</span>: Only revision information available
				</span>
				</CFOUTPUT>
			<CFELSE>
				<CFINCLUDE template="DispModelInfo.cfm">
			</CFIF>
			<CFOUTPUT>
		</td>
	</tr>
</table>
</CFOUTPUT>

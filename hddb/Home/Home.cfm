<cftry>
<!---
<CFQUERY name="Vendors" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>
--->
<CFQUERY name="Vendors" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>

<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" type="Dir" name="VendorDir">
<CFSET VendorCnt=Vendors.RecordCount>
<!---
<CFIF VendorDir.RecordCount GT VendorCnt>
	<CFSET VendorCnt=VendorDir.RecordCount>
</CFIF>
--->
<CFQUERY name="BenchModels" dbtype="Query">
	SELECT SUM(Cnt) AS Cnt
	FROM Vendors
</CFQUERY>
<CFQUERY name="Benchmarks" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
</CFQUERY>
<CFQUERY name="TotalModelCnt" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT distinct Model
	FROM diskspeed.models
	WHERE Model<>''
</CFQUERY>

<CFQUERY name="TopTenSpinners" datasource="#DSN#" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	SELECT v.Vendor, m.Model, m.Capacity, COUNT(b.ID) as Cnt
	FROM DiskSpeed.Models m
	INNER JOIN DiskSpeed.Vendors v ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (m.ModelID=b.ModelID)
	WHERE v.Vendor <> ''
	  AND m.SSD=0
	GROUP BY v.Vendor, m.Model, m.Capacity
	ORDER BY Cnt DESC
	LIMIT 0,10
</CFQUERY>
<CFQUERY name="TopTenSSD" datasource="#DSN#" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	SELECT v.Vendor, m.Model, m.Capacity, COUNT(b.ID) as Cnt
	FROM DiskSpeed.Models m
	INNER JOIN DiskSpeed.Vendors v ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (m.ModelID=b.ModelID)
	WHERE v.Vendor <> ''
	  AND m.SSD=1
	GROUP BY v.Vendor, m.Model, m.Capacity
	ORDER BY Cnt DESC
	LIMIT 0,10
</CFQUERY>


<CFQUERY name="qFastSpinners" datasource="#DSN#" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	SELECT v.Vendor, m.Model, m.Revision, m.Capacity, AVG(b2.Speed) as AvgSpeed, COUNT(b.ID) / 11 as TotalBenchmarks
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID AND m.SSD=0)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
    INNER JOIN DiskSpeed.Benchmarks b2 ON (b2.BenchmarkID=b.ID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
      AND (SELECT COUNT(*) FROM DiskSpeed.Benchmarks WHERE BenchmarkID=b2.BenchmarkID)=11
      AND b2.BenchmarkID IN (
				SELECT DISTINCT ba.ID
				FROM DiskSpeed.BenchmarkID ba
				WHERE ba.ModelID=m.ModelID
				  AND ba.DateStamp=(SELECT MAX(DateStamp) FROM DiskSpeed.BenchmarkID WHERE UserID=ba.UserID AND DriveID=ba.DriveID)
			)
    GROUP BY v.Vendor, m.Model, m.Revision, m.Capacity
    ORDER BY AvgSpeed DESC
</CFQUERY>
<CFQUERY name="FastSpinners" dbtype="Query">
	SELECT *
	FROM qFastSpinners
	WHERE TotalBenchmarks > 9
    ORDER BY AvgSpeed DESC
</CFQUERY>

<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" name="TotalModels" filter="default.png" type="file" recurse="true">

<CFOUTPUT>
<br><br>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td class="Arial White Size24">Drive Vendors:</td><td rowspan="4">&nbsp;</td><td class="Arial White Size24">#VendorCnt#</td>
	</tr>
	<tr>
		<td class="Arial White Size24">Drive Models:</td>&nbsp;</td><td class="Arial White Size24">#NumberFormat(TotalModelCnt.RecordCount,"9,999")#</td>
	</tr>
	<tr>
		<td class="Arial White Size24">Drive Benchmarks:</td><td class="Arial White Size24">#NumberFormat(BenchModels.Cnt,"9,999")#</td>
	</tr>
	<tr>
		<td class="Arial White Size24">Drive Model Images:</td><td class="Arial White Size24">#NumberFormat(TotalModels.RecordCount,"9,999")#</td>
	</tr>
</table>
<span class="Arial White Size24">
<br/>
All drive information benchmarks & heatmaps in the Model Database is submitted through the <a class="White" href="https://forums.unraid.net/topic/70636-diskspeed" target="_blank">DiskSpeed</a> Docker application
running on *nix hosts.<br/>
<br/>
</span>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td align="Center" class="Arial White Size18 Bold" colspan="5">Top Ten Drives</td>
	</tr>
	<tr>
		<td valign="top">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td colspan="3" class="Arial White Size18" align="Center">Total Spinners Tested</td>
				</tr>
				<CFLOOP index="CR" from="1" to="#TopTenSpinners.RecordCount#">
					<!--- KBytes returns 9.99 XB format, drop decimal --->
					<CFSET DispCapacity=KBytes(TopTenSpinners.Capacity[CR])>
					<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
					<tr>
						<td class="Arial White Size14 Right">#CR#.&nbsp;</td>
						<td><a href="index.cfm?View=Drives&Vendor=#TopTenSpinners.Vendor[CR]#&Model=#TopTenSpinners.Model[CR]#" class="Arial White Size14 NoLink">#TopTenSpinners.Vendor[CR]#</a>&nbsp;</td>
						<td><a href="index.cfm?View=Drives&Vendor=#TopTenSpinners.Vendor[CR]#&Model=#TopTenSpinners.Model[CR]#" class="Arial White Size14 NoLink">#TopTenSpinners.Model[CR]# (#DispCapacity#)</a></td>
					</tr>
				</CFLOOP>
			</table>
		</td>
		<td width="2%">&nbsp;</td>
		<td valign="top">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td colspan="3" class="Arial White Size18" align="Center"> Total SSDs Tested</td>
				</tr>
				<CFLOOP index="CR" from="1" to="#TopTenSSD.RecordCount#">
					<!--- KBytes returns 9.99 XB format, drop decimal --->
					<CFSET DispCapacity=KBytes(TopTenSSD.Capacity[CR])>
					<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
					<tr>
						<td class="Arial White Size14 Right">#CR#.&nbsp;</td>
						<td><a href="index.cfm?View=Drives&Vendor=#TopTenSSD.Vendor[CR]#&Model=#TopTenSSD.Model[CR]#" class="Arial White Size14 NoLink">#TopTenSSD.Vendor[CR]#</a>&nbsp;</td>
						<td><a href="index.cfm?View=Drives&Vendor=#TopTenSSD.Vendor[CR]#&Model=#TopTenSSD.Model[CR]#" class="Arial White Size14 NoLink">#TopTenSSD.Model[CR]# (#DispCapacity#)</a></td>
					</tr>
				</CFLOOP>
			</table>
		</td>
		<td width="2%">&nbsp;</td>
		<td valign="top">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td colspan="3" class="Arial White Size18" align="Center">Fastest Overall Avg Throughput</td>
				</tr>
				<CFSET Tot=0>
				<CFLOOP index="CR" from="1" to="#FastSpinners.RecordCount#">
					<CFIF Int(FastSpinners.TotalBenchmarks[CR]) EQ FastSpinners.TotalBenchmarks[CR]>
						<CFSET Tot=Tot + 1>
						<!--- KBytes returns 9.99 XB format, drop decimal --->
						<CFSET DispCapacity=KBytes(FastSpinners.Capacity[CR])>
						<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
						<CFSET AvgSpeed=FastSpinners.AvgSpeed[CR] / 1024 / 1024>
						<tr>
							<td class="Arial White Size14 Right">#Tot#.&nbsp;</td>
							<td><a href="index.cfm?View=Drives&Vendor=#FastSpinners.Vendor[CR]#&Model=#FastSpinners.Model[CR]#" class="Arial White Size14 NoLink">#FastSpinners.Vendor[CR]#</a>&nbsp;</td>
							<td><a href="index.cfm?View=Drives&Vendor=#FastSpinners.Vendor[CR]#&Model=#FastSpinners.Model[CR]#" class="Arial White Size14 NoLink">#FastSpinners.Model[CR]# Rev: #FastSpinners.Revision[CR]# (#DispCapacity#) - #NumberFormat(AvgSpeed,"9,999.9")# MB/sec</a></td>
						</tr>
						<CFIF Tot EQ 10>
							<CFBREAK>
						</CFIF>
					</CFIF>
				</CFLOOP>
				<tr>
					<td colspan="3" class="Arial White Size12">Only drives with 10+ benchmarks included</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</CFOUTPUT>


<!--- <cfdump var=#FastSpinners#> --->








<cfcatch type="any2">
<cfdump var=#cfcatch#>
</cfcatch>
</cftry>
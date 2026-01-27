<!--- Load in TeleportHQ page --->
<CFFILE action="read" file="#RootDir#/Templates/index.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">

<!--- Get Vendor Count--->
<CFQUERY name="Vendors" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT v.Vendor, Count(m.Model) AS Cnt
	FROM DiskSpeed.Vendors v
	INNER JOIN DiskSpeed.Models m ON (m.VendorID=v.ID)
	INNER JOIN DiskSpeed.BenchmarkID b ON (b.ModelID=m.ModelID)
	WHERE v.Vendor NOT IN ('','Generic','Unknown')
	GROUP BY v.Vendor
	ORDER BY v.Vendor
</CFQUERY>
<CFSET HTML=Replace(HTML,"[DriveVendors]",NumberFormat(Vendors.RecordCount,"9,999"))>

<!--- Get Drive Models --->
<CFQUERY name="TotalModelCnt" datasource="#DSN#" cachedwithin="#CreateTimeSpan(0,0,5,0)#">
	SELECT distinct Model
	FROM diskspeed.models
	WHERE Model<>''
</CFQUERY>
<CFSET HTML=Replace(HTML,"[DriveModels]",NumberFormat(TotalModelCnt.RecordCount,"9,999"))>

<!--- Get total benchmark count --->
<CFQUERY name="BenchModels" dbtype="Query">
	SELECT SUM(Cnt) AS Cnt
	FROM Vendors
</CFQUERY>
<CFSET HTML=Replace(HTML,"[DriveBenchmarks]",NumberFormat(BenchModels.Cnt,"9,999"))>

<!--- Fet bendor images count --->
<CFSET Fetch=0>
<CFSET DriveModelImages=0>
<cflock type="readonly" scope="Application" timeout="10" throwontimeout="NO">
	<CFIF StructKeyExists(Application,"DriveModelImages") EQ "NO">
		<CFSET Fetch=1>
	<CFELSE>
		<CFIF DateDiff("d",Application.DriveModelImagesFetchDate,Now()) GT 0>
			<CFSET Fetch=1>
		<CFELSE>
			<CFSET DriveModelImages=Application.DriveModelImages>
		</CFIF>
	</CFIF>
</cflock>
<CFIF Fetch EQ 1>
	<cflock type="exclusive" scope="Application" timeout="20" throwontimeout="NO">
		<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" name="TotalModels" filter="default.png" type="file" recurse="true">
		<CFSET Application.DriveModelImages=TotalModels.RecordCount>
		<CFSET Application.DriveModelImagesFetchDate=Now()>
	</cflock>
</CFIF>
<CFSET HTML=Replace(HTML,"[DriveModelImages]",NumberFormat(DriveModelImages,"9,999"))>


<!--- Fetch Top 10 Data --->
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
<CFLOOP index="CR" from="1" to="#TopTenSpinners.RecordCount#">
	<!--- KBytes returns 9.99 XB format, drop decimal --->
	<CFSET DispCapacity=KBytes(TopTenSpinners.Capacity[CR])>
	<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
	<CFSET HTML=Replace(HTML,"[A#CR#]","<a href=""ModelDatabase.cfm?Vendor=#TopTenSpinners.Vendor[CR]#&Model=#TopTenSpinners.Model[CR]#"">#TopTenSpinners.Vendor[CR]#</a>")>
	<CFSET HTML=Replace(HTML,"[B#CR#]","<a href=""ModelDatabase.cfm?Vendor=#TopTenSpinners.Vendor[CR]#&Model=#TopTenSpinners.Model[CR]#"">#TopTenSpinners.Model[CR]# (#DispCapacity#)</a>")>
</CFLOOP>


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
<CFLOOP index="CR" from="1" to="#TopTenSSD.RecordCount#">
	<!--- KBytes returns 9.99 XB format, drop decimal --->
	<CFSET DispCapacity=KBytes(TopTenSSD.Capacity[CR])>
	<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
	<CFSET HTML=Replace(HTML,"[C#CR#]","<a href=""ModelDatabase.cfm?Vendor=#TopTenSSD.Vendor[CR]#&Model=#TopTenSSD.Model[CR]#"">#TopTenSSD.Vendor[CR]#</a>")>
	<CFSET HTML=Replace(HTML,"[D#CR#]","<a href=""ModelDatabase.cfm?Vendor=#TopTenSSD.Vendor[CR]#&Model=#TopTenSSD.Model[CR]#"">#TopTenSSD.Model[CR]# (#DispCapacity#)</a>")>
</CFLOOP>

<CFQUERY name="qFastSpinners" datasource="#DSN#" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	SELECT v.Vendor, m.Model, m.Capacity, AVG(b2.Speed) as AvgSpeed, COUNT(b.ID) / 11 as TotalBenchmarks
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
    GROUP BY v.Vendor, m.Model, m.Capacity
    ORDER BY AvgSpeed DESC
</CFQUERY>
<CFQUERY name="FastSpinners" dbtype="Query">
	SELECT *
	FROM qFastSpinners
	WHERE TotalBenchmarks > 9
    ORDER BY AvgSpeed DESC
</CFQUERY>
<CFLOOP index="CR" from="1" to="#FastSpinners.RecordCount#">
	<!--- KBytes returns 9.99 XB format, drop decimal --->
	<CFSET DispCapacity=KBytes(FastSpinners.Capacity[CR])>
	<CFSET DispCapacity=Trim(NumberFormat(ListFirst(DispCapacity," "),"9999") & " " & ListLast(DispCapacity," "))>
	<CFSET AvgSpeed=FastSpinners.AvgSpeed[CR] / 1024 / 1024>
	<CFSET HTML=Replace(HTML,"[E#CR#]","<a href=""ModelDatabase.cfm?Vendor=#FastSpinners.Vendor[CR]#&Model=#FastSpinners.Model[CR]#"">#FastSpinners.Vendor[CR]#</a>")>
	<CFSET HTML=Replace(HTML,"[F#CR#]","<a href=""ModelDatabase.cfm?Vendor=#FastSpinners.Vendor[CR]#&Model=#FastSpinners.Model[CR]#"">#FastSpinners.Model[CR]# (#DispCapacity#) - #NumberFormat(AvgSpeed,"9,999.9")# MB/sec</a>")>
</CFLOOP>




<!--- Display HTML --->
<CFOUTPUT>#HTML#</CFOUTPUT>

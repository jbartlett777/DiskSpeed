<CFPARAM name="URL.DriveData" default="">
<CFPARAM name="FORM.DriveData" default="#URL.DriveData#">
<CFPARAM name="URL.h" default="">
<CFPARAM name="FORM.h" default="#URL.h#">

<CFIF FORM.h NEQ Hash(FORM.DriveData & URLEncodedFormat(FORM.DriveData))>
	<CFABORT>
</CFIF>
<CFIF Find(";",FORM.DriveData)>
	<CFABORT>
</CFIF>

<CFSET Data=Duplicate(DeserializeJSON(FORM.DriveData))>

<CFIF StructKeyExists(Data,"Version") EQ "NO">
	<CFSET Data.Version="">
	<CFSET Data.UserIDSHA="">
</CFIF>

<CFSET DriveData=Data.DriveData>
<CFSET BenchData=Data.BenchmarkData>

<CFQUERY name="AllVendors" datasource="mysql">SELECT * FROM DiskSpeed.Vendors</CFQUERY>

<CFLOOP index="i" from="1" to="#ArrayLen(DriveData)#">
	<CFINCLUDE template="SubmitDriveCleanup.cfm">

	<CFIF Skip EQ 0>
		<CFQUERY name="CheckVendor" dbtype="Query">SELECT * FROM AllVendors WHERE Vendor='#DriveData[i].Vendor#'</CFQUERY>
		<CFIF CheckVendor.RecordCount EQ 0>
			<CFQUERY datasource="mysql">INSERT INTO DiskSpeed.Vendors (Vendor) VALUES ('#DriveData[i].Vendor#')</CFQUERY>
			<CFQUERY name="AllVendors" datasource="mysql">SELECT * FROM DiskSpeed.Vendors</CFQUERY>
			<CFQUERY name="CheckVendor" dbtype="Query">SELECT * FROM AllVendors WHERE Vendor='#DriveData[i].Vendor#'</CFQUERY>
		</CFIF>
		<CFQUERY name="CheckModel" datasource="mysql">
			SELECT *
			FROM DiskSpeed.Models
			WHERE Model='#DriveData[i].Model#'
			AND Revision='#DriveData[i].Revision#'
			AND VendorID=#CheckVendor.ID#
		</CFQUERY>
		<CFIF CheckModel.RecordCount EQ 0>
			<CFQUERY datasource="mysql">
				INSERT INTO DiskSpeed.Models
					(VendorID, Model, Revision, Capacity,
					 SSD, RPM, SignalingSpeed,
					 LogicalSectorSize, PhysicalSectorSize,
					 MultipleSectorTransfer)
				VALUES
					(#CheckVendor.ID#, '#DriveData[i].Model#', '#DriveData[i].Revision#', #NULLNumber(DriveData[i].Capacity)#,
					 #DriveData[i].SSD#, #NULLNumber(DriveData[i].RPM)#, '#DriveData[i].SignalingSpeed#',
					 #NULLNumber(DriveData[i].LogicalSectorSize)#, #NULLNumber(DriveData[i].PhysicalSectorSize)#,
					 #NULLNumber(DriveData[i].MultipleSectorTransfer)#)
			</CFQUERY>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFIF Data.Version NEQ "">
	<CFQUERY name="UserInfo" datasource="mysql">
		SELECT ID
		FROM DiskSpeed.Users
		WHERE SHA='#Data.UserIDSHA#'
	</CFQUERY>
	<CFIF UserInfo.RecordCount EQ 0>
		<CFQUERY datasource="mysql">
			INSERT INTO DiskSpeed.Users (SHA) VALUES ('#Data.UserIDSHA#')
		</CFQUERY>
		<CFQUERY name="UserInfo" datasource="mysql">
			SELECT ID
			FROM DiskSpeed.Users
			WHERE SHA='#Data.UserIDSHA#'
		</CFQUERY>
	</CFIF>
</CFIF>
<cflock name="StoreBenchmarks" type="exclusive" throwontimeout="true" timeout="300">
<CFLOOP index="i" from="1" to="#ArrayLen(BenchData)#">
	<CFQUERY name="HDDB" datasource="mysql">
		SELECT ModelID
		FROM DiskSpeed.Models
		WHERE VendorID=(SELECT ID FROM DiskSpeed.Vendors WHERE Vendor='#BenchData[i].Vendor#')
		  AND Model='#BenchData[i].Model#'
		  AND Revision='#BenchData[i].Revision#'
	</CFQUERY>
	<CFIF HDDB.RecordCount NEQ 0>
		<cflock name="BenchmarkInsert" type="exclusive" throwontimeout="true" timeout="60">
			<CFIF Data.Version EQ "">
				<cfcontent type="text/text" reset="true">
				<CFOUTPUT><br><br>Benchmark uploading requires DiskSpeed Beta 6a or higher.<br><br><br><br></CFOUTPUT><CFFLUSH><CFABORT>
			<CFELSE>
				<CFQUERY datasource="mysql">
					INSERT INTO DiskSpeed.BenchmarkID
						(UserID, DriveID, DateStamp, ModelID, RandomSeek, SequentialSeek, DriveLatency)
					VALUES
						(#UserInfo.ID#,'#BenchData[i].SerialHash#',#CreateODBCDateTime(BenchData[i].DateStamp)#, #HDDB.ModelID#,
						'#BenchData[i].RandomSeek#','#BenchData[i].SequentialSeek#','#BenchData[i].DriveLatency#')
				</CFQUERY>
				<CFQUERY name="BenchID" datasource="mysql">
					SELECT ID
					FROM DiskSpeed.BenchmarkID
					WHERE UserID='#UserInfo.ID#'
					  AND DriveID='#BenchData[i].SerialHash#'
					  AND DateStamp=#CreateODBCDateTime(BenchData[i].DateStamp)#
				</CFQUERY>
			</CFIF>
			<CFIF StructKeyExists(Benchdata[i],"ReadMBs")>
				<CFQUERY datasource="mysql">
					INSERT INTO DiskSpeed.SSD_Benchmarks
						(BenchmarkID, ReadMBs, WriteMBs, BufferExceededAt, SustainedWriteMin, SustainedWriteMax)
					VALUES
						(#BenchID.ID#,#Val(BenchData[i].ReadMBs)#,#Val(BenchData[i].Burst)#,#Val(BenchData[i].BurstEnd)#,#Val(BenchData[i].WriteMin)#,#Val(BenchData[i].WriteMax)#)
				</CFQUERY>
			<CFELSE>
				<CFLOOP index="q" from="1" to="#ArrayLen(BenchData[i].BenchMark)#">
					<CFQUERY datasource="mysql">
						INSERT INTO DiskSpeed.Benchmarks
							(BenchmarkID, Spot, Speed)
						VALUES
							(#BenchID.ID#, #Val(BenchData[i].BenchMark[q][1])#, #Val(BenchData[i].BenchMark[q][2])#)
					</CFQUERY>
				</CFLOOP>
			</CFIF>
		</cflock>
	</CFIF>
</CFLOOP>
</cflock>

<cfcontent type="text/text" reset="true">
<CFOUTPUT>[Ok]</CFOUTPUT>

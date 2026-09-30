<CFQUERY name="Models" datasource="#DSN#">
	SELECT ModelID, Model, SchemaName
	FROM backblaze2.Models
	ORDER BY Model
</CFQUERY>

<!--- Update Total Drives count --->
<CFQUERY datasource="#DSN#">
	UPDATE backblaze2.models m
	SET m.TotalDrives=(SELECT COUNT(1) FROM backblaze2.serial_numbers WHERE ModelID=m.ModelID)
</CFQUERY>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<title>Set Drive Stats</title>
</head>
<body>
<script>
function S(txt) {
	document.getElementById('Status').innerHTML=txt;
}
</script>
Start at #TS()#<br>
<div id="Status"></div>
</CFOUTPUT>
<CFFLUSH>

<CFLOOP index="CR" from="1" to="#Models.RecordCount#">
	<CFSET SchemaName=SafeSchemaName(Models.Model[CR])>
	<CFSET Out("Updating statistics for #Models.Model[CR]# - Total Drives (#CR#/#Models.RecordCount#)")>
	<CFQUERY name="SerialCounts" datasource="#DSN#">
		SELECT SerialID,COUNT(1) AS TotalDriveDays
		FROM backblaze.#Models.SchemaName[CR]#
		GROUP BY SerialID
	</CFQUERY>
	<CFQUERY name="SUM" dbtype="Query">
		SELECT SUM(TotalDriveDays) as TotalDriveDays
		FROM SerialCounts
	</CFQUERY>
	<CFQUERY datasource="#DSN#">
		UPDATE backblaze2.Models
		SET DriveDays=#Val(SUM.TotalDriveDays)#
		WHERE ModelID=#Models.ModelID[CR]#
	</CFQUERY>

	<CFSET Out("Updating statistics for #Models.Model[CR]# - Failed Drives (#CR#/#Models.RecordCount#)")>
	<CFQUERY name="FailedCounts" datasource="#DSN#">
		SELECT SerialID, SUM(Failure) as Failed
		FROM backblaze.#Models.SchemaName[CR]#
		GROUP BY SerialID
	</CFQUERY>
	<CFQUERY name="OnlyFailed" dbtype="Query">
		SELECT SerialID, Failed
		FROM FailedCounts
		WHERE Failed > 0
	</CFQUERY>
	<CFIF OnlyFailed.RecordCount GT 0>
		<CFQUERY datasource="#DSN#">
			UPDATE backblaze2.serial_numbers
			SET Failed=1
			WHERE SerialID IN (#ValueList(OnlyFailed.SerialID)#)
			AND Failed=0
		</CFQUERY>
		<CFQUERY name="FailedDriveSum" dbtype="Query">
			SELECT COUNT(1) as FailedDrives
			FROM OnlyFailed
		</CFQUERY>
		<CFQUERY datasource="#DSN#">
			UPDATE backblaze2.Models
			SET FailedDrives=#FailedDriveSum.FailedDrives#
			WHERE ModelID=#Models.ModelID[CR]#
		</CFQUERY>
	</CFIF>

</CFLOOP>


<CFQUERY name="Models" datasource="#DSN#">
	SELECT ModelID, Model, SchemaName, Capacity, TotalDrives, DriveDays
	FROM backblaze2.models
	WHERE `Ignore`=0
	ORDER BY Model
</CFQUERY>
<!---
<CFLOOP index="CR" from="1" to="#Models.RecordCount#">
	<!--- Get total failed drives for the model --->
	<CFQUERY name="Failed" datasource="#DSN#">
		<CFSET SQL=SQL & "">
	</CFQUERY> 
</CFLOOP>
--->


<!--- Update table Backblazze.MonthlyFailureRates --->
<!--- Get most recent month processed --->
<CFQUERY name="GetRec" datasource="#DSN#">
	SELECT Year, Month
	FROM backblaze2.monthlyfailurerates
	ORDER BY ID DESC
	LIMIT 0,1
</CFQUERY>
<CFIF GetRec.RecordCount EQ 0>
	<CFSET Y=2013>
	<CFSET M=4>
<CFELSE>
	<CFSET Y=GetRec.Year>
	<CFSET M=GetRec.Month>
</CFIF>
<!--- Loop over year & months --->
<CFLOOP index="CurrYear" from="#Y#" to="#Year(now())#">
	<CFLOOP index="CurrMonth" from="#M#" to="12">
		<!--- Build SQL --->
		<CFLOOP index="ModelIdx" from="1" to="#Models.RecordCount#">
			<CFSET StartDate=CreateDate(CurrYear,CurrMonth,1)>
			<CFSET EndDate=CreateDate(CurrYear,CurrMonth,DaysInMonth(StartDate))>
			<CFSET Out("Fetching failure rates for #CurrYear#-#Replace(RJustify(CurrMonth,2)," ","0")#: #Models.Model[ModelIdx]#")>
			<CFQUERY name="Stats" datasource="#DSN#">
				SELECT (SELECT COUNT(1)
						FROM backblaze.#Models.SchemaName[ModelIdx]#
						WHERE `Date` BETWEEN <cfqueryparam CFSQLType="cf_sql_date" value="#StartDate#"> AND <cfqueryparam CFSQLType="cf_sql_date" value="#EndDate#">
					   ) AS TotalDrives,
					   (SELECT COUNT(1)
						FROM backblaze.#Models.SchemaName[ModelIdx]#
						WHERE `Date` BETWEEN <cfqueryparam CFSQLType="cf_sql_date" value="#StartDate#"> AND <cfqueryparam CFSQLType="cf_sql_date" value="#EndDate#">
					    AND failure=1
					   ) AS FailedDrives
			</CFQUERY>
			<CFIF Stats.TotalDrives GT 0>
				<CFSET FailRate=Stats.FailedDrives / Stats.TotalDrives / 0.01>
				<CFQUERY datasource="#DSN#">
					INSERT IGNORE INTO backblaze2.monthlyfailurerates
						(`Year`,`Month`,ModelID,TotalDrives,FailedDrives,FailRate)
					VALUES
						(<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrYear#">,
						 <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrMonth#">,
						 <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Models.ModelID[ModelIdx]#">,
						 <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Stats.TotalDrives#">,
						 <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Stats.FailedDrives#">,
						 <cfqueryparam CFSQLType="CF_SQL_FLOAT" value="#FailRate#">)
				</CFQUERY>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
	<CFSET M=1>
</CFLOOP>


<CFOUTPUT>
<CFSET Out("Done")>
</CFOUTPUT>
<CFFLUSH>

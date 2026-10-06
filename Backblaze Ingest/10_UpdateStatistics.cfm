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

<!--- Get the first date of the current quarter loaded --->
<CFQUERY name="MaxDate" datasource="#DSN#">
	SELECT MAX(LastDate) AS LastDate
	FROM backblaze2.serial_numbers
	WHERE LastDate IS NOT NULL
</CFQUERY>
<CFSET FirstQuarterDate=CreateDate(
									Year(MaxDate.LastDate),
									(Quarter(MaxDate.LastDate) - 1) * 3 + 1,
									1
								  )>

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

	<!--- Get Serials for Model --->
	<CFQUERY name="Serials" datasource="#DSN#">
		SELECT SerialID
		FROM backblaze2.serial_numbers
		WHERE ModelID=#Models.ModelID[CR]#
		  AND (
				 ActiveDays IS NULL
			  OR LastDate IS NULL
			  OR LastDate >= '#DateFormat(FirstQuarterDate,"yyyy-mm-dd")#'
		  )
	</CFQUERY>
	<CFSET LastSec=Second(Now())>
	<CFLOOP index="SID" from="1" to="#Serials.RecordCount#">
		<CFIF Second(Now()) NEQ LastSec>
			<CFSET LastSec=Second(Now())>
			<CFSET Out("Updating statistics for #Models.Model[CR]# - Drive Age (#CR#/#Models.RecordCount#) - #SID#/#Serials.RecordCount#")>
		</CFIF>
		<CFQUERY datasource="#DSN#">
			UPDATE backblaze2.serial_numbers
			SET ActiveDays=(SELECT COUNT(1) FROM backblaze.#Models.SchemaName[CR]# WHERE SerialID=#Serials.SerialID[SID]#)
			WHERE SerialID=#Serials.SerialID[SID]#
		</CFQUERY>
	</CFLOOP>

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
	<!--- Set failed date --->
	<CFQUERY datasource="#DSN#">
		UPDATE backblaze2.serial_numbers s
		SET s.FailedDate=(
			SELECT Date
			FROM backblaze.#Models.SchemaName[CR]#
			WHERE SerialID=s.SerialID
			AND Failure=1
			LIMIT 0,1
		)
		WHERE s.ModelID=#Models.ModelID[CR]#
		AND s.Failed=1
		AND s.FailedDate IS NULL
	</CFQUERY>

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

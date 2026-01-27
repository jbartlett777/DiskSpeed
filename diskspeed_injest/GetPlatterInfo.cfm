<CFPARAM name="URL.Vendor" default="">
<CFPARAM name="URL.Model" default="">
<CFPARAM name="URL.Debug" default="0">
<CFPARAM name="URL.H" default="">

<CFSET DriveVendor="">
<CFSET DriveModel="">

<CFSET Ok=1>
<CFIF LCase(Hash(URL.Vendor & "|" & URL.Model)) NEQ URL.H>
	<CFSET Ok=0>
	<CFIF URL.Debug><CFOUTPUT>Hash Mismatch<br></CFOUTPUT></CFIF>
<CFELSE>
	<CFIF ListLen(URL.Vendor) NEQ ListLen(URL.Model)>
		<CFSET Ok=0>
		<CFIF URL.Debug><CFOUTPUT>Vendor/Model List not equal<br></CFOUTPUT></CFIF>
	</CFIF>
</CFIF>
<CFIF NOT OK>
	<CFIF URL.Debug EQ "0"><CFABORT></CFIF>
</CFIF>

<CFLOOP index="i" from="1" to="#ListLen(URL.Vendor)#">
	<CFSET tmpVendor=ReturnRegExAsString("[A-Za-z0-9 -]*",ListGetAt(URL.Vendor,i))>
	<CFSET tmpModel=ReturnRegExAsString("[A-Za-z0-9 -]*",ListGetAt(URL.Model,i))>
	<CFIF tmpVendor NEQ ListGetAt(URL.Vendor,i) OR tmpModel NEQ ListGetAt(URL.Model,i)>
		<CFSET Ok=0>
	<CFELSE>
		<CFSET DriveVendor=ListAppend(DriveVendor,tmpVendor)>
		<CFSET DriveModel=ListAppend(DriveModel,tmpModel)>
	</CFIF>
</CFLOOP>

<CFSET Info=ArrayNew(1)>

<CFLOOP index="i" from="1" to="#ListLen(DriveVendor)#">
	<CFSET CurrVendor=ListGetAt(DriveVendor,i)>
	<CFSET CurrModel=UCase(ListGetAt(DriveModel,i))>
	<CFSET CurrModel=Replace(CurrModel,"/","-","ALL")>
	<CFSET CurrModel=Replace(CurrModel,":","-","ALL")>
	<CFSET i2=StructNew()>
	<CFSET i2.Vendor=CurrVendor>
	<CFSET i2.Model=CurrModel>
	<CFIF URL.Debug>
		<CFOUTPUT>
		CurrVendor: [#CurrVendor#]<br>
		CurrModel: [#CurrModel#]<br>
		</CFOUTPUT>
	</CFIF>

	<CFQUERY name="PlatterInfo" datasource="mysql">
		SELECT ShortStroked, Platters, Heads
		FROM DiskSpeed.PlatterInfo
		WHERE Vendor='#CurrVendor#'
		  AND Model='#CurrModel#'
	</CFQUERY>
	<CFIF URL.Debug EQ 1>
		<CFDUMP var=#PlatterInfo#>
	</CFIF>
	<CFIF PlatterInfo.RecordCount EQ 1>
		<CFSET i2.ShortStroked=PlatterInfo.ShortStroked>
		<CFSET i2.PlatterCnt=PlatterInfo.Platters>
		<CFSET i2.HeadCnt=PlatterInfo.Heads>
		<CFSET Info[ArrayLen(Info)+1]=Duplicate(i2)>
	</CFIF>

</CFLOOP>

<CFSET JSON=SerializeJSON(Info)>

<CFIF URL.Debug EQ 0>
	<cfcontent type="text/json" reset="true">
<CFELSE>
	<CFOUTPUT>Results:<br></CFOUTPUT>
</CFIF>
<CFOUTPUT>#JSON#</CFOUTPUT>


<!--- <cfdump var=#info#>
<cfdump var=#data#> --->






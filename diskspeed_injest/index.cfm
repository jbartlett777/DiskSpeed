<CFPARAM name="URL.Max" default="99">
<CFPARAM name="URL.Vendor" default="">
<CFPARAM name="URL.Model" default="">
<CFPARAM name="URL.Debug" default="0">
<CFPARAM name="URL.H" default="">
<CFPARAM name="URL.Version" default="2018-04-01">

<CFSET DriveVendor="">
<CFSET DriveModel="">
<CFSET MaxRows=Val(URL.Max)>

<CFSET Ok=1>
<CFIF LCase(Hash(URL.Vendor & "|" & URL.Model & "|" & URL.Max)) NEQ URL.H>
	<CFSET Ok=0>
	<CFIF URL.Debug><CFOUTPUT>Hash Mismatch<br></CFOUTPUT></CFIF>
<!--- <CFELSE>
	<CFIF ListLen(URL.Vendor) NEQ ListLen(URL.Model)>
		<CFSET Ok=0>
		<CFIF URL.Debug>
			<CFOUTPUT>
			Vendor/Model List not equal, an error is about to happen!<br>
			Vendor: [#URL.Vendor#]<br>
			Model: [#URL.Model#]<br>
			</CFOUTPUT>
		</CFIF>
	</CFIF> --->
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
		<CFIF URL.Debug>
			<CFOUTPUT>
			DriveVendor: [#DriveVendor#]<br>
			DriveModel: [#DriveModel#]<br>
			</CFOUTPUT>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFSET Info=ArrayNew(1)>

<CFIF DirectoryExists("#RootDir#/Debug") EQ "NO">
	<CFDIRECTORY action="Create" directory="#RootDir#/Debug" mode="755">
</CFIF>


<CFLOOP index="i" from="1" to="#ListLen(DriveVendor)#">
	<CFSET CurrVendor=ListGetAt(DriveVendor,i)>
	<CFSET CurrModel=UCase(ListGetAt(DriveModel,i))>
	<CFSET CurrModel=Replace(CurrModel,"/","-","ALL")>
	<CFSET CurrModel=Replace(CurrModel,":","-","ALL")>
	<CFSET VendorDir="#RootDir#/Drives/#CurrVendor#">
	<CFSET ModelDir="#VendorDir#/#CurrModel#">
	<CFSET i2=StructNew()>
	<CFSET i2.Vendor=CurrVendor>
	<CFSET i2.NewVendor="">
	<CFSET i2.Model=CurrModel>
	<CFSET i2.Image="">
	<!--- <CFIF Debug><cfoutput>Vendior Dir: #VendorDir#<br>Model Dir: #ModelDir#<br></cfoutput></CFIF> --->
	<!--- Could be a SSD with no vendor or wrong vendor, let's try to find the model  --->
	<CFIF DirectoryExists(ModelDir) EQ "NO">
		<CFDIRECTORY action="list" directory="#RootDir#/Drives" name="VendorSearch" filter="#CurrModel#" type="Dir" recurse="true">
		<CFIF URL.Debug><CFDUMP Var=#VendorSearch#></CFIF>
		<CFIF VendorSearch.RecordCount GT 0>
			<CFSET CurrVendor=ListLast(Replace(VendorSearch.Directory[1],"\","/","ALL"),"/")>
			<CFSET i2.NewVendor=CurrVendor>
			<CFSET VendorDir="#RootDir#/Drives/#CurrVendor#">
			<CFSET ModelDir="#VendorDir#/#CurrModel#">
		</CFIF>
	</CFIF>
	<CFIF URL.Debug>
		<CFOUTPUT>
		CurrVendor: [#CurrVendor#]<br>
		CurrModel: [#CurrModel#]<br>
		VendorDir: [#VendorDir#]<br>
		ModelDir: [#ModelDir#]<br>
		Found: [#DirectoryExists(ModelDir)#]<hr>
		</CFOUTPUT>
		<CFIF StructKeyExists(variables,"VendorSearch")>
			<cfdump var=#VendorSearch#>
		</CFIF>
	</CFIF>
	<CFIF NOT DirectoryExists(ModelDir)>
		<CFSET i2.Found=0>
		<CFSET MissDir="#RootDir#/Missing/#URL.Version#/#CurrVendor#/#CurrModel#">
		<CFIF DirectoryExists(MissDir) EQ "NO">
			<CFDIRECTORY action="Create" directory="#MissDir#" CreatePath="true" mode="755">
		</CFIF>
	<CFELSE>
		<CFSET i2.Found=1>
		<CFDIRECTORY action="list" directory="#ModelDir#" variable="DIR" filter="*.png" sort="datelastmodified">
		<CFFILE action="readbinary" file="#ModelDir#/#Dir.Name[1]#" variable="image">
		<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
			<CFIF CR GT MaxRows>
				<CFBREAK>
			</CFIF>
			<CFIF CR EQ 1>
				<CFFILE action="read" file="#ModelDir#/default.json" variable="jsstyle">
			<CFELSE>
				<CFSET FN=ModelDir & "/" & ListDeleteAt(Dir.Name[CR],ListLen(Dir.Name[CR],"."),".") & ".json">
				<CFFILE action="read" file="#FN#" variable="jsstyle">
			</CFIF>
			<CFSET i2.Image=BinaryEncode(image,"Base64")>
			<CFSET style=DeserializeJSON(jsstyle)>
			<CFLOOP index="CurrKey" list="#StructKeyList(style)#">
				<CFSET i2[CurrKey]=style[CurrKey]>
			</CFLOOP>
			<CFSET Info[ArrayLen(Info)+1]=Duplicate(i2)>
		</CFLOOP>
	</CFIF>
</CFLOOP>

<CFSET JSON=SerializeJSON(Info)>
<CFSET CurrTime=Now()>
<CFSET FN=DateFormat(CurrTime,"yyyy-mm-dd") & "_" & TimeFormat(CurrTime,"HH:mm:ss") & "." & Replace(RJustify(TimeFormat(CurrTime,"l"),3)," ","0","ALL")>

<CFPARAM name="URL.Max" default="99">
<CFPARAM name="URL.Vendor" default="">
<CFPARAM name="URL.Model" default="">

<CFSET Out="Vendor: [#URL.Vendor#]" & Chr(10) &
		   "Model: [#URL.Model#]" & Chr(10) &
		   "Max: [#URL.Max#]" & Chr(10) &
		   "H: [#URL.H#]" & Chr(10) &
		   JSON>

<cftry>
	<CFFILE action="write" file="#RootDir#/Debug/#FN#" output="#Out#" addnewline="NO" mode="644">
<CFCATCH Type="Any">
	<!--- Eat all errors --->
</CFCATCH>
</CFTRY>


<CFIF URL.Debug EQ 0>
	<cfcontent type="text/json" reset="true">
<CFELSE>
	<cfdump var=#Info#>
	<CFOUTPUT>Results:<br></CFOUTPUT>
</CFIF>
<CFOUTPUT>#JSON#</CFOUTPUT>


<!--- <cfdump var=#info#>
<cfdump var=#data#> --->
<CFPARAM name="URL.FetchDrives" default="">
<CFPARAM name="URL.UserID" default="">
<CFPARAM name="URL.Version" default="1">
<CFPARAM name="URL.Debug" default="0">

<CFIF URL.Debug>
	<CFOUTPUT>
	FetchImages: [#URL.FetchDrives#]<br>
	UserID: [#URL.UserID#]<br>
	<hr>
	</CFOUTPUT>
</CFIF>

<CFSET I=ArrayNew(1)>

<CFLOOP index="CurrDrive" list="#URL.FetchDrives#">
	<CFSET CurrVendor=ReturnRegExAsString("[A-Za-z0-9 -]*",ListFirst(CurrDrive,"~"))>
	<CFSET CurrModel=ReturnRegExAsString("[A-Za-z0-9 -]*",ListLast(CurrDrive,"~"))>
	<CFSET DrivePath=RootDir & "/Drives/" & CurrVendor & "/" & CurrModel>
	<CFIF URL.Debug>
		<CFOUTPUT>
		CurrVendor: [#CurrVendor#]<br>
		CurrModel: [#CurrModel#]<br>
		DrivePath: [#DrivePath#]<br>
		DirectoryExists: #DirectoryExists(DrivePath)#<br>
		</CFOUTPUT>
	</CFIF>

	<CFSET Img="">
	<CFIF DirectoryExists(DrivePath)>
		<CFIF FileExists("#DrivePath#/#URL.UserID#.png")>
			<CFSET Img=URL.UserID & ".png">
			<CFSET JSON=URL.UserID & "_default.json">
		<CFELSE>
			<CFDIRECTORY action="list" directory="#DrivePath#" variable="Images" filter="*.png" sort="DateLastModified">
			<CFIF Images.RecordCount GT 0>
				<CFSET Img=Images.Name[1]>
				<CFSET JSON="default.json">
			</CFIF>
		</CFIF>
	<CFELSE>
		<CFSET MissDir="#RootDir#/Missing/#URL.Version#/#CurrVendor#/#CurrModel#">
		<CFIF DirectoryExists(MissDir) EQ "NO">
			<CFDIRECTORY action="Create" directory="#MissDir#" CreatePath="true" mode="755">
		</CFIF>
	</CFIF>

	<CFSET NR=ArrayLen(I) + 1>

	<CFIF Img EQ "">
		<CFSET I[NR]=StructNew()>
		<CFSET I[NR].Found=0>
		<CFSET I[NR].Vendor=CurrVendor>
		<CFSET I[NR].Model=CurrModel>
	<CFELSE>
		<CFFILE action="readbinary" file="#DrivePath#/#Img#" variable="image">
		<CFFILE action="read" file="#DrivePath#/#JSON#" variable="ConfigJSON">
		<CFSET I[NR]=DeserializeJSON(ConfigJSON)>
		<CFSET I[NR].Found=1>
		<CFSET I[NR].Image=BinaryEncode(image,"Base64")>
		<CFSET I[NR].Vendor=CurrVendor>
		<CFSET I[NR].Model=CurrModel>
		<CFIF StructKeyExists(I[NR],"TextCSS") EQ "NO">
			<CFSET I[NR].TextOverlay=1>
			<CFSET I[NR].TextRotation=0>
			<CFSET I[NR].TextCSS="width:128px;font:20px Arial;color:##000000;text-indent:45px;padding-top:83px;height:107px;cursor:default;">
			<CFSET I[NR].TextX=64>
			<CFSET I[NR].TextY=95>
			<CFSET I[NR].CenterX=1>
			<CFSET I[NR].CenterY=1>
			<CFSET I[NR].TextFont="Arial">
			<CFSET I[NR].TextBold=0>
			<CFSET I[NR].TextItalics=0>
			<CFSET I[NR].FontColor="##000000">
			<CFSET I[NR].FontSize=20>
		</CFIF>
	</CFIF>

	<CFIF URL.Debug>
		<CFOUTPUT><hr></CFOUTPUT>
	</CFIF>
</CFLOOP>

<CFIF URL.Debug>
	<cfdump var=#I#>
</CFIF>

<CFSET JSON=SerializeJSON(I)>

<CFIF URL.Debug EQ 0>
	<cfcontent type="text/json" reset="true">
</CFIF>
<CFOUTPUT>#JSON#</CFOUTPUT>



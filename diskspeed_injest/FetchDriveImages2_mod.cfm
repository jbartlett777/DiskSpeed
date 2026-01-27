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

<CFSET Info=StructNew()>
<CFSET IM=StructNew()>
<CFSET SMART=StructNew()>

<CFLOOP index="CurrDrive" list="#URL.FetchDrives#">
	<CFSET DriveID=ListFirst(CurrDrive,"~")>
	<CFSET CurrVendor=ListGetAt(CurrDrive,2,"~")>
	<CFSET CurrModel=ListLast(CurrDrive,"~")>
	<CFSET CurrVendor=ReturnRegExAsString("[A-Za-z0-9 -]*",CurrVendor)>
	<CFSET CurrModel=ReturnRegExAsString("[A-Za-z0-9 -]*",CurrModel)>
	<CFSET DrivePath=RootDir & "/Drives/" & CurrVendor & "/" & CurrModel>
	<CFIF URL.Debug>
		<CFOUTPUT>
		DriveID: [#DriveID#]<br>
		CurrVendor: [#CurrVendor#]<br>
		CurrModel: [#CurrModel#]<br>
		DrivePath: [#DrivePath#]<br>
		DirectoryExists: #DirectoryExists(DrivePath)#<br>
		</CFOUTPUT>
	</CFIF>

	<CFIF FileExists("#DrivePath#/SMART.txt") EQ "NO">
		<CFIF StructKeyExists(SMART,CurrVendor) EQ "NO">
			<CFSET SMART[CurrVendor]=StructNew()>
		</CFIF>
		<CFSET SMART[CurrVendor][CurrModel]=1>
	</CFIF>


	<CFSET Img="">
	<CFIF DirectoryExists(DrivePath) EQ "NO">
		<CFIF URL.Debug><CFOUTPUT>Vendor Model not found, searching. </CFOUTPUT></CFIF>
		<!--- Try to find the model in all vendors --->
		<CFDIRECTORY action="list" directory="#RootDir#/Drives" filter="#CurrModel#" type="dir" recurse="true" name="SearchModel">
		<CFIF SearchModel.RecordCount GT 0>
			<CFSET CurrVendor=ListLast(Replace(SearchModel.Directory[1],"\","/","ALL"),"/")>
			<CFSET DrivePath=RootDir & "/Drives/" & CurrVendor & "/" & CurrModel>
			<CFIF URL.Debug><CFOUTPUT>Found.<br></CFOUTPUT></CFIF>
		<CFELSE>
			<CFIF URL.Debug><CFOUTPUT>Not found.<br></CFOUTPUT></CFIF>
		</CFIF>
	</CFIF>
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

	<CFIF Img EQ "">
		<CFSET I[DriveID]=StructNew()>
		<CFSET I[DriveID].Found=0>
	<CFELSE>
		<CFFILE action="readbinary" file="#DrivePath#/#Img#" variable="image">
		<CFFILE action="read" file="#DrivePath#/#JSON#" variable="ConfigJSON">
		<CFSET BImage=BinaryEncode(image,"Base64")>
		<CFSET H=Hash(BImage)>
		<CFIF StructKeyExists(IM,H) EQ "NO">
			<CFSET IM["I"&H]=BImage>
			<CFIF URL.Debug>
				<CFOUTPUT><img src="data:image/png;base64, #BIMage#"><br></CFOUTPUT>
			</CFIF>
		</CFIF>
		<CFSET I[DriveID]=DeserializeJSON(ConfigJSON)>
		<CFSET I[DriveID].Found=1>
		<CFSET I[DriveID].Image="I" & H>
	</CFIF>
	<CFSET I[DriveID].Vendor=CurrVendor>
	<CFIF StructKeyExists(I[DriveID],"TextCSS") EQ "NO">
		<CFSET I[DriveID].TextOverlay=1>
		<CFSET I[DriveID].TextRotation=0>
		<CFSET I[DriveID].TextCSS="width:128px;font:20px Arial;color:##000000;text-indent:45px;padding-top:83px;height:107px;cursor:default;">
		<CFSET I[DriveID].TextX=64>
		<CFSET I[DriveID].TextY=95>
		<CFSET I[DriveID].CenterX=1>
		<CFSET I[DriveID].CenterY=1>
		<CFSET I[DriveID].TextFont="Arial">
		<CFSET I[DriveID].TextBold=0>
		<CFSET I[DriveID].TextItalics=0>
		<CFSET I[DriveID].FontColor="##000000">
		<CFSET I[DriveID].FontSize=20>
	</CFIF>

	<CFIF URL.Debug>
		<CFOUTPUT><hr></CFOUTPUT>
	</CFIF>
</CFLOOP>

<CFSET Ret=StructNew()>
<CFSET Ret.ImageData=IM>
<CFSET Ret.DriveData=I>
<CFSET Ret.SMART=SMART>

<CFIF URL.Debug>
	<cfdump var=#Ret#>
</CFIF>

<CFSET JSON=SerializeJSON(Ret)>

<CFIF URL.Debug EQ 0>
	<cfcontent type="text/json" reset="true">
</CFIF>
<CFOUTPUT>#JSON#</CFOUTPUT>



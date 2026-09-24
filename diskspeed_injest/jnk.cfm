<CFDIRECTORY action="list" directory="#RootDir#" recurse="yes" filter="default.json" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="read" file="#Dir.Directory[CR]#\#Dir.Name[CR]#" variable="JSConfig">
	<CFSET i=DeserializeJSON(JSConfig)>
	<CFIF i.TextCSS EQ "display:none;">
		<CFSET i.TextOverlay=0>
		<CFSET JSConfig=SerializeJSON(i)>
		<CFFILE action="write" file="#Dir.Directory[CR]#\#Dir.Name[CR]#" output="#JSConfig#" addnewline="NO">
	</CFIF>
</CFLOOP>


<cfoutput>Done. #now()#</cfoutput>












<cfabort>

<CFDIRECTORY action="list" directory="#RootDir#" recurse="yes" filter="default.json" name="Dir">
<CFLOOP index="CR" from="1" to="#Dir.RecordCount#">
	<CFFILE action="read" file="#Dir.Directory[CR]#\#Dir.Name[CR]#" variable="JSConfig">
	<CFSET i=DeserializeJSON(JSConfig)>
	<CFOUTPUT>#Dir.Directory[CR]#<br></CFOUTPUT>
	<CFIF i.TextCSS NEQ "display:none;">
		<CFSET i.TextCSS="width:128px;font:20px Arial;color:ffffff;text-indent:45px;padding-top:73px;height:99px;cursor:default;">
		<CFSET JSConfig=SerializeJSON(i)>
		<CFFILE action="write" file="#Dir.Directory[CR]#\#Dir.Name[CR]#" output="#JSConfig#" addnewline="NO">
	</CFIF>
</CFLOOP>


<cfoutput>Done. #now()#</cfoutput>












<cfabort>

<CFQUERY name="Data" datasource="#DSN#">
	SELECT v.Vendor, m.Model, m.Image, m.Interface, m.RPM, m.Cache
	FROM DiskSpeed.Vendors v, DiskSpeed.Models m
	WHERE m.VendorID=v.id
	  AND m.TextOverlay=1
</CFQUERY>

<CFSET Config=StructNew()>
<CFSET Config.TextOverlay=1>
<CFSET Config.TextX=64>
<CFSET Config.TextY=86>
<CFSET Config.CenterX=1>
<CFSET Config.CenterY=1>
<CFSET Config.FontSize=20>
<CFSET Config.TextRotation=0>
<CFSET Config.TextFont="Arial">
<CFSET Config.TextBold=0>
<CFSET Config.TextItalics=0>
<CFSET Config.FontColor="ffffff">
<CFSET Config.TextCSS="color:black; font-size:30px; vertical-align:middle; text-align:center; line-height:175px;">
<CFSET JSConfig=SerializeJSON(Config)>

<CFLOOP index="CR" from="1" to="#Data.RecordCount#">
	<CFSET OutDir="#RootDir#\#LCase(Data.Vendor[CR])#\#UCase(Data.Model[CR])#">
	<CFSET FN1="#RootDir#\#LCase(Data.Vendor[CR])#\#Data.Image[CR]#">
	<CFSET FN2="#OutDir#\#Data.Image[CR]#">
	<CFIF DirectoryExists("#OutDir#") EQ "NO">
		<CFDIRECTORY action="create" directory="#OutDir#">
	</CFIF>
	<CFIF FileExists(FN2) EQ "NO">
		<CFFILE action="copy" source="#FN1#" destination="#FN2#">
	</CFIF>
	<CFSET Info=StructNew()>
	<CFSET Info.Interface=Data.Interface>
	<CFSET Info.RPM=Data.RPM>
	<CFSET Info.Cache=Data.Cache>
	<CFSET JSInfo=SerializeJSON(Info)>
	<CFFILE action="write" file="#OutDir#/info.json" output="#JSInfo#" addnewline="NO">
	<CFFILE action="write" file="#OutDir#/default.json" output="#JSConfig#" addnewline="NO">
</CFLOOP>


<CFQUERY name="Data" datasource="#DSN#">
	SELECT v.Vendor, m.Model, m.Image, m.Interface, m.RPM, m.Cache
	FROM DiskSpeed.Vendors v, DiskSpeed.Models m
	WHERE m.VendorID=v.id
	  AND m.TextOverlay=0
</CFQUERY>

<CFSET Config.TextCSS="display:none;">
<CFSET JSConfig=SerializeJSON(Config)>

<CFLOOP index="CR" from="1" to="#Data.RecordCount#">
	<CFSET OutDir="#RootDir#\#LCase(Data.Vendor[CR])#\#UCase(Data.Model[CR])#">
	<CFSET FN1="#RootDir#\#LCase(Data.Vendor[CR])#\#Data.Image[CR]#">
	<CFSET FN2="#OutDir#\#Data.Image[CR]#">
	<CFIF DirectoryExists("#OutDir#") EQ "NO">
		<CFDIRECTORY action="create" directory="#OutDir#">
	</CFIF>
	<CFIF FileExists(FN2) EQ "NO">
		<CFFILE action="copy" source="#FN1#" destination="#FN2#">
	</CFIF>
	<CFSET Info=StructNew()>
	<CFSET Info.Interface=Data.Interface>
	<CFSET Info.RPM=Data.RPM>
	<CFSET Info.Cache=Data.Cache>
	<CFSET JSInfo=SerializeJSON(Info)>
	<CFFILE action="write" file="#OutDir#/info.json" output="#JSInfo#" addnewline="NO">
	<CFFILE action="write" file="#OutDir#/default.json" output="#JSConfig#" addnewline="NO">
</CFLOOP>


<cfoutput>Done. #now()#</cfoutput>

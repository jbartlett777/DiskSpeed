<CFSET ImgFN=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir & "/image.png">

<CFFILE action="readbinary" file="#ImgFN#" variable="image">

<CFSET D=HW[Key].Ports[PortNo]>
<CFSET Out=StructNew()>
<CFSET Out.Config=StructNew()>
<CFSET Out.Config.TextOverlay=d.Config.TextOverlay>
<CFSET Out.Config.TextRotation=d.Config.TextRotation>
<CFSET Out.Config.TextCSS=d.Config.TextCSS>
<CFSET Out.Config.TextBold=d.Config.TextBold>
<CFSET Out.Config.TextItalics=d.Config.TextItalics>
<CFSET Out.Config.TextX=d.Config.TextX>
<CFSET Out.Config.TextY=d.Config.TextY>
<CFSET Out.Config.CenterX=d.Config.CenterX>
<CFSET Out.Config.CenterY=d.Config.CenterY>
<CFSET Out.Config.FontColor=d.Config.FontColor>
<CFSET Out.Config.TextFont=d.Config.TextFont>
<CFSET Out.Config.FontSize=d.Config.FontSize>
<!--- <CFSET Out.Info=StructNew()>
<CFSET Out.Info.Interface=d.Config.Interface>
<CFSET Out.Info.Cache=d.Config.Cache>
<CFSET Out.Info.RPM=d.Config.RPM> --->
<CFSET Out.Vendor=d.Attrib.Vendor>
<CFSET Out.Model=d.Attrib.Model>
<CFSET Out.UserID=UserID>
<CFSET Out.Image=BinaryEncode(image,"Base64")>

<CFSET JSON=SerializeJSON(Out)>

<CFOUTPUT>
<div id="SubmitStatus">Status: Submitting drive information...</div>
</CFOUTPUT>
<CFFLUSH>
<!---<CFSET StrangeJourney="https://johnwbartlett.com">--->
<CFHTTP URL="#StrangeJourney#/diskspeed/SubmitDrive.cfm" method="POST">
	<CFHTTPPARAM type="formfield" name="json" value="#JSON#" encoded="NO">
</CFHTTP>

<CFOUTPUT>#Chr(60)#script></CFOUTPUT>
<CFIF CFHTTP.Status_Code EQ 200>
	<CFOUTPUT>document.getElementById('SubmitStatus').innerHTML='Status: #JSStringFormat(StripCRLF(CFHTTP.FileContent))#';</CFOUTPUT>
	<CFSET HW[Key].Ports[PortNo].Config.DriveEdited=0>
	<CFSET json=SerializeJSON(HW)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#PersistDir#/storage.json" mode="666" output="#json#" addnewline="NO">
	</cflock>
	<CFOUTPUT>#Chr(60)#/script></CFOUTPUT>
<CFELSE>
	<CFOUTPUT>
	document.getElementById('SubmitStatus').innerHTML='Status: Not sent. HTTP Status Code #CFHTTP.Status_Code# returned.';
	#Chr(60)#/script>
	URL: #StrangeJourney#/diskspeed/SubmitDrive.cfm<br>
	</CFOUTPUT>
	<CFIF DiskSpeedDeveloper>
		<CFDUMP var=#cfhttp#>
	</CFIF>
</CFIF>


<!--- <cfdump var=#out#> --->
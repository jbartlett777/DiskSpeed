<!--- Single thread this process for the drive image optimization called from ScanControllers.cfm --->
<cflock name="EditDrive" type="exclusive" throwontimeout="false" timeout="90">

<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>
<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
<CFSET Ref=DeserializeJSON(json)>

<!--- <cfdump var=#form#>
<cfdump var=#HW[FORM.Key].Ports[FORM.PortNo].Config#> --->

<CFPARAM name="FORM.SubmitButton" default="0">
<CFPARAM name="FORM.TextOverlay" default="0">
<CFPARAM name="FORM.CenterX" default="0">
<CFPARAM name="FORM.CenterY" default="0">
<CFPARAM name="FORM.TextRotation" default="0">
<CFPARAM name="FORM.TextColor" default="ffffff">
<CFPARAM name="FORM.TextFont" default="Arial">
<CFPARAM name="FORM.TextSize" default="20">
<CFPARAM name="FORM.TextBold" default="0">
<CFPARAM name="FORM.TextItalics" default="0">
<CFPARAM name="FORM.SyncModels" default="N">
<CFPARAM name="FORM.AutoSubmit" default="">

<CFIF FORM.SubmitButton EQ "Reset Image">
	<CFSET NeedImage="#FORM.Key#|#FORM.PortNo#">
	<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.DefaultImage=1>
	<CFSET RefreshDrive=1>
	<CFSET NoFlush=1>
	<CFINCLUDE TEMPLATE="GetInitialDriveImage.cfm">
	<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.DriveEdited=0>
	<CFSET json=SerializeJSON(HW)>
	<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
	<CFLOCATION URL="index.cfm?Drive=#FORM.Key#|#FORM.PortNo#" addtoken="NO">
</CFIF>

<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextOverlay=FORM.TextOverlay>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextRotation=FORM.TextRotation>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextCSS=FORM.NewCSS>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.CenterX=FORM.CenterX>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.CenterY=FORM.CenterY>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextX=FORM.TextLocX>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextY=FORM.TextLocY>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.FontColor=FORM.TextColor>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextFont=FORM.TextFont>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.FontSize=FORM.TextSize>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextBold=FORM.TextBold>
<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.TextItalics=FORM.TextItalics>
<CFIF FORM.AutoSubmit EQ "Y">
	<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.DriveEdited=0>
	<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.OptVer2_9=1>
<CFELSE>
	<CFSET HW[FORM.Key].Ports[FORM.PortNo].Config.DriveEdited=1>
</CFIF>




<CFSET jsonfile=PersistDir & "/driveinfo/" & HW[FORM.Key].Ports[FORM.PortNo].Config.SaveDir & "/config.json">
<CFSET json=SerializeJSON(HW[FORM.Key].Ports[FORM.PortNo].Config)>
<CFFILE action="write" file="#jsonfile#" output="#json#" addnewline="NO" mode="666">

<!--- <cfdump var=#HW[FORM.Key].Ports[FORM.PortNo].Config#> --->

<CFIF FORM.SyncModels EQ "Y">
	<CFSET SourceDir=PersistDir & "/driveinfo/" & HW[FORM.Key].Ports[Form.PortNo].Config.SaveDir>
	<CFSET KeyList=Ref.Vendor[HW[FORM.Key].Ports[Form.PortNo].Attrib.Vendor][HW[FORM.Key].Ports[Form.PortNo].Attrib.Model]>
	<CFLOOP index="CurrKey" list="#KeyList#">
		<CFSET DKey=ListFirst(CurrKey,"|")>
		<CFSET DPortNo=ListLast(CurrKey,"|")>
		<CFSET OrigConfig=Duplicate(HW[FORM.Key].Ports[FORM.PortNo].Config)>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextOverlay=OrigConfig.TextOverlay>
		<CFSET HW[DKey].Ports[DPortNo].Config.GoogleFont=OrigConfig.GoogleFont>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextRotation=OrigConfig.TextRotation>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextCSS=OrigConfig.TextCSS>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextFont=OrigConfig.TextFont>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextBold=OrigConfig.TextBold>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextItalics=OrigConfig.TextItalics>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextX=OrigConfig.TextX>
		<CFSET HW[DKey].Ports[DPortNo].Config.TextY=OrigConfig.TextY>
		<CFSET HW[DKey].Ports[DPortNo].Config.CenterX=OrigConfig.CenterX>
		<CFSET HW[DKey].Ports[DPortNo].Config.CenterY=OrigConfig.CenterY>
		<CFSET HW[DKey].Ports[DPortNo].Config.ImageWidth=OrigConfig.ImageWidth>
		<CFSET HW[DKey].Ports[DPortNo].Config.ImageHeight=OrigConfig.ImageHeight>
		<CFSET HW[DKey].Ports[DPortNo].Config.FontColor=OrigConfig.FontColor>
		<CFSET HW[DKey].Ports[DPortNo].Config.FontSize=OrigConfig.FontSize>
		<CFSET HW[DKey].Ports[DPortNo].Config.Random=GetTickCount() & RandRange(0,99999)>
		<CFSET DestnDir=PersistDir & "/driveinfo/" & HW[DKey].Ports[DPortNo].Config.SaveDir>
		<CFIF SourceDir NEQ DestnDir>
			<CFDIRECTORY action="list" type="file" directory="#DestnDir#" name="Dir2">
			<CFLOOP index="CR" From="1" to="#Dir2.RecordCount#">
				<CFFILE action="delete" file="#DestnDir#/#Dir2.Name[CR]#">
			</CFLOOP>
			<CFFILE action="copy" source="#SourceDir#/config.json" destination="#DestnDir#/config.json">
			<CFFILE action="copy" source="#SourceDir#/image.png" destination="#DestnDir#/image.png">
			<CFSET FN="#RootDir#/images/inuse/#CurrInstance#/" & HW[DKey].Ports[DPortNo].Config.SaveDir & ".png">
			<CFFILE action="copy" source="#SourceDir#/image.png" destination="#FN#">
		</CFIF>
	</CFLOOP>
</CFIF>

<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
<CFSET tmp=URLEncodedFormat("#FORM.Key#|#FORM.PortNo#")>

</cflock>

<CFIF FORM.AutoSubmit EQ "Y">
	<CFOUTPUT>
	Done
	<script>
	parent.ProcessImg();
	</script>
	</CFOUTPUT>
	<CFFLUSH>
<CFELSE>
	<CFLOCATION URL="index.cfm?Drive=#tmp#" addtoken="NO">
</CFIF>
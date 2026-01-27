<CFSET DriveModels=StructNew()>
<CFDIRECTORY action="list" directory="#RootDir#\Drives" type="dir" variable="Vendors">

<CFLOOP index="VCR" from="1" to="#Vendors.RecordCount#">
	<CFSET DriveModels[Vendors.Name[VCR]]="">
	<CFDIRECTORY action="list" directory="#RootDir#\Drives\#Vendors.Name[VCR]#" type="dir" variable="Models">
	<CFLOOP index="MCR" from="1" to="#Models.RecordCount#">
		<CFSET DriveModels[Vendors.Name[VCR]]=ListAppend(DriveModels[Vendors.Name[VCR]],Models.Name[MCR])>
	</CFLOOP>
</CFLOOP>

<CFSET json=SerializeJSON(DriveModels)>

<cfcontent type="text/json" reset="true">
<CFOUTPUT>#JSON#</CFOUTPUT>
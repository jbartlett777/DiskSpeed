<CFSET Key=ListFirst(FORM.Drive,"|")>
<CFSET PortNo=ListLast(FORM.Drive,"|")>

<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>
<CFIF FileExists("#PersistDir#/vendor_override.json")>
	<CFFILE action="read" file="#PersistDir#/vendor_override.json" variable="json">
	<CFSET VendorOverride=DeserializeJSON(json)>
<CFELSE>
	<CFSET VendorOverride=StructNew()>
</CFIF>

<CFSET HW[Key].Ports[PortNo].Attrib.Vendor=FORM.NewVendor>
<CFSET VendorOverride[HW[Key].Ports[PortNo].Attrib.Serial]=FORM.NewVendor>

<CFINCLUDE TEMPLATE="../BuildQuickRef.cfm">

<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(Ref)>
<CFFILE action="write" file="#PersistDir#/storageref.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(VendorOverride)>
<CFFILE action="write" file="#PersistDir#/vendor_override.json" output="#json#" addnewline="NO" mode="666">

<CFLOCATION URL="/DispDrive.cfm?Drive=#URLEncodedFormat(FORM.Drive)#" addtoken="NO">

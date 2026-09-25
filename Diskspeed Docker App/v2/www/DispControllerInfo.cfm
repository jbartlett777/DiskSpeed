<CFIF StructKeyExists(variables,"HW") EQ "NO">
	<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
		<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
		<CFSET HW=DeserializeJSON(json)>
		<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
		<CFSET Ref=DeserializeJSON(json)>
		<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
		<CFSET HWTree=DeserializeJSON(json)>
		<CFFILE action="read" file="#PersistDir#/usbtree.json" variable="json">
		<CFSET USBTree=DeserializeJSON(json)>
		<CFFILE action="read" file="#PersistDir#/miscref.json" variable="json">
		<CFSET MiscRef=DeserializeJSON(json)>
	<CFELSE>
		<CFABORT>
	</CFIF>
</CFIF>
<CFINCLUDE TEMPLATE="Styles.cfm">
<CFOUTPUT>
<body>
</CFOUTPUT>

<CFPARAM name="variables.i_icon" default="0">
<CFPARAM name="variables.NVMEHeader" default="0">

<CFIF HW[Key].NVMe EQ 1 AND NVMEHeader EQ 1>
	<cfexit method="exittemplate">
</CFIF>

<CFIF HW[Key].USB EQ 1>
	<CFSET i_icon=0>
</CFIF>

<CFIF Key EQ "Unknown">
	<CFOUTPUT>
		<span class="Size18">Unknown Controller</span><br>
		<span class="Size5"><br></span>
	</CFOUTPUT>
<CFELSEIF HW[Key].NVMe EQ 1>
	<CFOUTPUT>
		<span class="Size24">Non-Volatile memory controller</span><br>
		<span class="Size5"><br></span>
	</CFOUTPUT>
<CFELSE>
	<CFOUTPUT>
	<div>
		<div class="Size24 FloatLeft">#HW[Key].Config.Device#</div>
		<CFIF i_icon>
			<div class="AlignTop"><a href="javascript:UpdateRightDiv('DispController.cfm?Controller=#URLEncode(Key)#')"><img src="images/info_icon.png" width="16" height="16" border="0"></a></div>
		</CFIF>
	</div>
	<br class="Size5 BR" />
	<CFIF StructKeyExists(HW[Key].Config,"SVendor")>
		<CFIF ListFirst(HW[Key].Config.SVendor," ") EQ "Unknown">
			<span class="Size18">#HW[Key].Config.Vendor#</span>
		<CFELSE>
			<span class="Size18">#HW[Key].Config.SVendor#</span>
			<CFIF HW[Key].Config.SVendor NEQ HW[Key].Config.Vendor>
				(#HW[Key].Config.Vendor#)
			</CFIF>
		</CFIF>
	<CFELSE>
		#HW[Key].Config.Vendor#
	</CFIF>
	<br>
	#HW[Key].Config.Class#
	<span class="Size5"><br><br></span>
	</CFOUTPUT>
</CFIF>

<CFIF HW[Key].NVMe EQ 1>
	<CFSET NVMEHeader=1>
</CFIF>

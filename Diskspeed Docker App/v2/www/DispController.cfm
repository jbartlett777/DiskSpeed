<CFPARAM name="URL.Benchmark" default="0">

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

<CFSET Key=URL.Controller>

<CFINCLUDE TEMPLATE="KillDiskPIDs.cfm">

<CFSET i_icon=0>
<CFINCLUDE TEMPLATE="DispControllerInfo.cfm">

<CFIF StructKeyExists(MiscRef.PCIeSlots,Key)>
	<CFOUTPUT><span class="Bold">Type:</span> Add-on Card in PCIe Slot #MiscRef.PCIeSlots[Key].Slot# (#MiscRef.PCIeSlots[Key].Type#)<br></CFOUTPUT>
<CFELSE>
	<CFOUTPUT><span class="Bold">Type:</span> Onboard Controller<br></CFOUTPUT>
</CFIF>

<CFSET PCIeVerRef="2.5,5,8,16,32,64">
<CFIF ListFindNoCase("Unknown,Create",Key) EQ 0>
	<CFOUTPUT>
	<CFSET CK=0>
	<CFIF HW[Key].Config.LnkSta.Speed EQ HW[Key].Config.LnkCap.Speed AND HW[Key].Config.LnkSta.Speed NEQ "" AND HW[Key].Config.LnkCap.Speed NEQ "">
		<CFSET CK=1>
		<span class="Bold">Current & Maximum Link Speed:</span> #HW[Key].Config.LnkSta.Speed#
		<CFSET PCIeVer=ListFind(PCIeVerRef,Val(HW[Key].Config.LnkSta.Speed))>
		<CFIF PCIeVer GT 0>
			(PCIe #PCIeVer#)
		</CFIF>
		width #HW[Key].Config.LnkSta.Width# (#HW[Key].Config.LnkCap.Throughput# max throughput)<br>
	<CFELSE>
		<CFIF HW[Key].Config.LnkSta.Speed NEQ "">
			<CFSET CK=1>
			<span class="Bold">Current Link Speed:</span> #HW[Key].Config.LnkSta.Speed#
			<CFSET PCIeVer=ListFind(PCIeVerRef,Val(HW[Key].Config.LnkSta.Speed))>
			<CFIF PCIeVer GT 0>
				(PCIe #PCIeVer#)
			</CFIF>
			width #HW[Key].Config.LnkSta.Width# (#HW[Key].Config.LnkSta.Throughput# max throughput)<br>
		</CFIF>
		<CFIF HW[Key].Config.LnkCap.Speed NEQ "">
			<CFSET CK=1>
			<span class="Bold">Maximum Link Speed:</span> #HW[Key].Config.LnkCap.Speed#
			<CFSET PCIeVer=ListFind(PCIeVerRef,Val(HW[Key].Config.LnkCap.Speed))>
			<CFIF PCIeVer GT 0>
				(PCIe #PCIeVer#)
			</CFIF>
			width #HW[Key].Config.LnkCap.Width# (#HW[Key].Config.LnkCap.Throughput# max throughput)<br>
		</CFIF>
	</CFIF>
	<!--- <CFIF StructKeyExists(HW[Key].Config,"PCISpeed") AND CK EQ 0>
		<span class="Bold">Maximum PCI Speed:</span> #HW[Key].Config.PCISpeed#<br>
	</CFIF> --->
		<CFIF IsNumeric(HW[Key].Config.Width)>
			<span class="Bold">Bus:</span> #HW[Key].Config.Width# @ #HW[Key].Config.Clock#<br>
		</CFIF>
		<!--- <span class="Bold">Driver:</span> #HW[Key].Config.Configuration.Driver#<br> --->
		<CFIF HW[Key].Config.Capabilities NEQ "">
			<span class="Bold">Capabilities:</span> #HW[Key].Config.Capabilities#<br>
		</CFIF>
	<br>
	<div class="DivTable">
	</CFOUTPUT>
</CFIF>

<CFLOOP index="PortNo" from="1" to="#ArrayLen(HW[Key].Ports)#">
	<CFOUTPUT>
	<div class="DivRow">
		<div class="DivCell NOBR">Port #PortNo#:&nbsp;</div>
	<CFIF HW[Key].Ports[PortNo].DriveID EQ "">
		<div class="DivCell Grey NOBR">N/A</div>
	<CFELSE>
		<div class="DivCell NOBR">#HW[Key].Ports[PortNo].DriveID#&nbsp;</div>
		<div class="DivCell Right NOBR">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#&nbsp;</div>
		<div class="DivCell NOBR">
			<CFIF StructKeyExists(HW[Key].Ports[PortNo].Attrib,"vendor")>#HW[Key].Ports[PortNo].Attrib.vendor#</CFIF>
			#HW[Key].Ports[PortNo].Attrib.Model#
			<CFIF HW[Key].Ports[PortNo].Attrib.Rev NEQ ""> Rev #HW[Key].Ports[PortNo].Attrib.Rev#</CFIF>
			Serial: #HW[Key].Ports[PortNo].Attrib.Serial#
			<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ ""> (#HW[Key].Ports[PortNo].UNRAIDSlot#)</CFIF>
		</div>
	</CFIF>
	</div>
	</CFOUTPUT>
</CFLOOP>
<CFOUTPUT>
</div>
</CFOUTPUT>

<CFIF HW[Key].TotalDrives GT 1>
	<CFOUTPUT><br></CFOUTPUT>
	<CFIF URL.Benchmark EQ "0">
		<CFSET BenchFile="#PersistDir#/controller/bandwidth/" & HW[Key].BandwidthHash & "/benchmark.html">
		<CFIF FileExists(BenchFile)>
			<CFFILE action="read" file="#BenchFile#" variable="BenchData">
			<CFOUTPUT>#BenchData#<br></CFOUTPUT>
		</CFIF>
	<CFELSE>
		<CFINCLUDE template="TestControllerBandwidth.cfm">
		<CFOUTPUT><br></CFOUTPUT>
	</CFIF>
	<CFOUTPUT>
	<br>
	<form method="get">
	<input type="Hidden" name="controller" value="#URL.Controller#">
	<input type="Hidden" name="Benchmark" value="1">
	<input type="submit" value="Benchmark Controller">
	</form>
	</CFOUTPUT>
</CFIF>



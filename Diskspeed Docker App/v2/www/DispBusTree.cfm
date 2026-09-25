
<CFOUTPUT>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td class="Arial Size14 Bold NoBr Hand" onClick="DispSystemBusTree()" id="SystemBusTreeMenu">System Bus Tree</td>
		<td class="Size14 Bold">&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td class="Arial Size14 Bold Grey NoBr Hand" onClick="DispUSBBusTree()" id="USBBusTreeMenu">USB Bus Tree</td>
	</tr>
</table>
<script language="JavaScript">
function DispSystemBusTree()
{
	$(SystemBusTreeMenu).removeClass('Grey');
	$(USBBusTreeMenu).addClass('Grey');
	document.getElementById('SystemBusTree').style.display='block';
	document.getElementById('USBBusTree').style.display='none';
}
function DispUSBBusTree()
{
	$(USBBusTreeMenu).removeClass('Grey');
	$(SystemBusTreeMenu).addClass('Grey');
	document.getElementById('SystemBusTree').style.display='none';
	document.getElementById('USBBusTree').style.display='block';
}
</script>
<div id="SystemBusTree">
</CFOUTPUT>
<!--- Get root devices --->
<CFDIRECTORY action="list" directory="/sys/devices" filter="pci*" sort="name" name="PCIDir">
<CFLOOP index="i" from="1" to="#PCIDir.RecordCount#">
	<!--- Get root device's information --->
	<CFTRY>
		<cfexecute name="/usr/bin/lspci" arguments="-D -s #Mid(PCIDir.Name[i],4,99)#:00.0" timeout="300" variable="lspci" />
		<CFSET lspci=StripCRLF(lspci)>
	<CFCATCH Type="Any">
		<CFSET lspci="">
	</CFCATCH>
	</CFTRY>
	<CFIF lspci NEQ "">
		<CFSET lspci=ListDeleteAt(lspci,1," ")>
		<CFOUTPUT>
		<table border="0" cellpadding="0" cellspacing="0">
		<tr><td class="Size12 NOBR" colspan="2">#lspci#<br><!--- [#PCIDir.Name[i]#] ---></td></tr>
		</CFOUTPUT>
		<CFSET BusTree(HWTree,PCIDir.Name[i])>
		<CFOUTPUT>
		</table>
		</CFOUTPUT>
	</CFIF>
</CFLOOP>
<CFOUTPUT>
</div>
<div id="USBBusTree" style="display:none">
</CFOUTPUT>
<CFLOOP index="Bus" from="1" to="#ArrayLen(USBTree)#">
	<CFSET USBBusTree(USBTree[Bus])>
</CFLOOP>
<CFOUTPUT>
<span class="Size12"><span class="Bold">Note:</span> Device Speeds represent the current operating speed which is driven by the max speed of the port</span>
</div>
</CFOUTPUT>




<cffunction name="USBBusTree" returntype="Any" output="true">
    <cfargument name="Tree" required="true" type="Struct">

	<CFSET VAR DispName="">
	<CFSET VAR PortNo=0>
	<CFSET VAR Class="">

	<CFOUTPUT><table border="0" cellpadding="0" cellspacing="0"></CFOUTPUT>

	<CFIF StructKeyExists(Arguments.Tree,"idVendor") EQ "NO">
		<CFSET Arguments.Tree.idVendor="">
	</CFIF>
	<CFIF StructKeyExists(Arguments.Tree,"iProduct") EQ "NO">
		<CFSET Arguments.Tree.iProduct="Empty">
	</CFIF>
	<CFIF StructKeyExists(Arguments.Tree,"idProduct") EQ "NO">
		<CFSET Arguments.Tree.idProduct="Empty">
	</CFIF>
	<CFIF StructKeyExists(Arguments.Tree,"bInterfaceClass") EQ "NO">
		<CFSET Arguments.Tree.bInterfaceClass="Unknown">
	</CFIF>
	<CFIF StructKeyExists(Arguments.Tree,"iManufacturer") EQ "NO">
		<CFSET Arguments.Tree.iManufacturer="Unknown">
	</CFIF>

	<CFIF Arguments.Tree.idVendor EQ "Linux Foundation">
		<CFOUTPUT><tr><td class="Size12 NOBR" colspan="3"><span class="Bold">System Bus #Bus#, #Arguments.Tree.TotalPorts# port<CFIF #Arguments.Tree.TotalPorts# NEQ 1>s</CFIF></span> - #(USBTree[Bus].Speed / 8)# MB/s<br></td></tr></CFOUTPUT>
	<CFELSE>
		<CFIF Len(Arguments.Tree.iProduct) GT Len(Arguments.Tree.idProduct)>
			<CFSET DispName=Arguments.Tree.iProduct>
		<CFELSE>
			<CFSET DispName=Arguments.Tree.idProduct>
		</CFIF>
		<CFIF DispName EQ "">
			<CFSET DispName=Arguments.Tree.bInterfaceClass>
			<CFIF Arguments.Tree.bInterfaceClass NEQ Arguments.Tree.bInterfaceProtocol>
				<CFIF Arguments.Tree.bInterfaceProtocol NEQ "">
					<CFSET DispName=DispName & " - " & Arguments.Tree.bInterfaceProtocol>
				<CFELSE>
					<CFSET DispName=DispName & " - " & Arguments.Tree.bInterfaceClass>
				</CFIF>
			</CFIF>
		</CFIF>
		<CFIF Arguments.Tree.iManufacturer NEQ "">
			<CFSET DispName=DispName & ", " & Arguments.Tree.iManufacturer>
		</CFIF>
		<CFIF DispName EQ "Hub">
			<CFSET DispName=Arguments.Tree.TotalPorts & " port hub">
		</CFIF>
		<CFIF Arguments.Tree.bInterfaceClass EQ "Hub">
			<CFIF FindNoCase("port",DispName) EQ 0>
				<CFSET DispName=Arguments.Tree.TotalPorts & " port " & DispName>
			</CFIF>
		</CFIF>
		<CFOUTPUT><tr><td class="Size12 NOBR" colspan="3">#DispName#<CFIF DispName NEQ "Empty"> - #(USBTree[Bus].Speed / 8)# MB/s</CFIF><br></td></tr></CFOUTPUT>
	</CFIF>
	<CFIF Arguments.Tree.bInterfaceClass EQ "Hub">
		<CFLOOP index="PortNo" from="1" to="#ArrayLen(Arguments.Tree.Ports)#">
			<CFOUTPUT>
			<tr>
				<td class="Nav<CFIF PortNo EQ ArrayLen(Arguments.Tree.Ports)>3<CFELSE>2</CFIF>"></td>
				<td class="Size12 Bold NOBR" colspan="1" valign="top" width="1">Port&nbsp;#Arguments.Tree.Ports[PortNo].PortNo#:&nbsp;</td>
				<td colspan="2">
				</CFOUTPUT>
				<CFSET USBBusTree(Arguments.Tree.Ports[PortNo])>
				<CFOUTPUT>
				</td>
			</tr>
			</CFOUTPUT>
		</CFLOOP>

	<CFELSE>
	</CFIF>

	<CFOUTPUT></table></CFOUTPUT>

</cffunction>




<cffunction name="BusTree" returntype="Any" output="true">
    <cfargument name="Tree" required="true" type="Array">
    <cfargument name="Root" required="true" type="String">

	<CFSET VAR SortList="">
	<CFSET VAR SortedIDs="">
	<CFSET VAR i=0>
<!--- <cfoutput><table border="0"><tr><td></cfoutput><cfdump var=#arguments.tree#><cfoutput></td></tr></table></cfoutput> --->
	<!--- Create list of strings for sorting --->
	<CFLOOP index="i" from="1" to="#ArrayLen(Arguments.Tree)#">
		<!--- <cfoutput><tr><td colspan="2">[#Arguments.Root#][#ListGetAt(Arguments.Tree[i]["SysFS ID"],2,"/")#]</td></tr></cfoutput> --->
		<CFIF Find(Arguments.Root,ListGetAt(Arguments.Tree[i]["SysFS ID"],2,"/"))><!---  OR Left(Arguments.Tree[i]["SysFS ID"],3) NEQ "pci" --->
			<CFIF Arguments.Tree[i]["Hardware Class"] EQ "bridge" AND ArrayLen(Arguments.Tree[i].Children) EQ 0>
				<!--- Don't display bridges with no attached devices at this time --->
			<CFELSE>
				<CFSET SortList=ListAppend(SortList,LJustify(Arguments.Tree[i]["Hardware Class"],20) & "|" & LJustify(Arguments.Tree[i].Model,255) & "|" & i,"~")>
			</CFIF>
		</CFIF>
	</CFLOOP>
	<!--- <cfoutput><hr>#replace(sortlist,"~","<br>","all")#<hr></cfoutput> --->
	<CFSET SortList=ListSort(SortList,"textnocase","asc","~")>
	<CFLOOP index="i" from="1" to="#ListLen(SortList,'~')#">
		<CFSET SortedIDs=ListAppend(SortedIDs,ListLast(ListGetAt(SortList,i,"~"),"|"))>
	</CFLOOP>
	<CFLOOP index="i" list="#SortedIDs#">
		<CFOUTPUT>
		<tr>
			<td class="Nav<CFIF i EQ ListLast(SortedIDs)>3<CFELSE>2</CFIF>"></td>
			<td class="Size12 NOBR" colspan="2" valign="top">
				#Arguments.Tree[i].Device#
				<CFIF StructKeyExists(Arguments.Tree[i],"USBBus")>
					<span class="Bold"> (Bus ###Arguments.Tree[i].USBBus#)</span>
				</CFIF>
		</CFOUTPUT>
		<CFIF ArrayLen(Arguments.Tree[i].Children) GT 0>
			<CFIF ListFindNoCase("storage,usb controller",Arguments.Tree[i]["Hardware Class"])>
				<CFOUTPUT><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="Bold">#ArrayLen(Arguments.Tree[i].Children)# drive<CFIF ArrayLen(Arguments.Tree[i].Children) NEQ 1>s</CFIF></span></CFOUTPUT>
			<CFELSE>
				<CFOUTPUT><table border="0" cellpadding="0" cellspacing="0"><tr></CFOUTPUT>
				<CFSET BusTree(Arguments.Tree[i].Children,Arguments.Root)>
				<CFOUTPUT></tr></table></CFOUTPUT>
			</CFIF>
		</CFIF>
		<CFOUTPUT>
			</td>
		</tr>
		</CFOUTPUT>
	</CFLOOP>

</cffunction>

<cfoutput><br></cfoutput>

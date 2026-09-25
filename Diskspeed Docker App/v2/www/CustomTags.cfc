<cfcomponent displayname="Utils" output="false">

	<CFFUNCTION name="GetBlockDevices">
		<CFSET var tmp="">
		<CFSET var BlockDevices="">
		<CFSET VAR CurrLine="">
		<!--- Block devices --->
		<cfexecute name="/bin/ls" arguments="-l /sys/dev/block" variable="tmp"  timeout="90" />
		<CFLOOP index="CurrLine" from="1" to="#ListLen(tmp,Chr(10))#">
			<CFIF Find("/usb",CurrLine) EQ 0 AND Find("/virtual",CurrLine) EQ 0>
				<CFSET BlockDevices=BlockDevices & CurrLine>
			</CFIF>
		</CFLOOP>
		<!--- Another block devices tree --->
		<cfexecute name="/bin/lsblk" variable="tmp" timeout="90" />
		<CFSET BlockDevices=BlockDevices & tmp>
		<!--- Partitions (causes drives to spin up and forces app to wait so disabled)
		<cfexecute name="/sbin/parted" arguments="-l -s" variable="tmp"  timeout="90" />
		<CFSET BlockDevices=BlockDevices & tmp> --->
		<!--- Manually mounted drives through "Unassigned Devices" plugin --->
		<CFIF DirectoryExists("/mnt/UNRAID/disks")>
			<cfexecute name="/bin/ls" arguments="/mnt/UNRAID/disks" variable="tmp"  timeout="90" />
			<CFSET BlockDevices=BlockDevices & tmp>
		</CFIF>

		<CFRETURN BlockDevices>
	</CFFUNCTION>

</cfcomponent>
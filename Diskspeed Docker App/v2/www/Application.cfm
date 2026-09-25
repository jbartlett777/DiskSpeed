<cfsetting enablecfoutputonly="true" requesttimeout="600">
<cfapplication clientmanagement="false" sessionmanagement="true" name="DiskSpeed" applicationtimeout="#CreateTimeSpan(1,0,0,0)#" sessiontimeout="#CreateTimeSpan(1,0,0,0)#">

<CFSET StartTick=GetTickCount()>
<CFINCLUDE TEMPLATE="CustomTags.cfm" runonce="yes">
<CFINCLUDE TEMPLATE="environment.cfm" runonce="yes">
<CFOBJECT name="Utils" component="CustomTags">

<!--- Test if we have write access to the mapped volume --->
<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
	<CFTRY>
		<CFFILE action="write" file="#PersistDir#/jnk.txt" output="0" addnewline="NO">
		<CFFILE action="delete" file="#PersistDir#/jnk.txt">
		<CFCATCH Type="Any">
			<CFOUTPUT>This application is not able to write to its external directory mapped to the directory "/tmp/DiskSpeed" Please enable Read/Write permission.</CFOUTPUT>
			<CFABORT>
		</CFCATCH>
	</CFTRY>
</cflock>

<!--- Fetch Docker env --->
<!--- Locate cpuset.effective_cpus or cpuset.cpus.effective file --->
<CFSET ActiveCPUs="">
<CFIF FileExists("/sys/fs/cgroup/cpuset/cpuset.effective_cpus")>
	<CFSET ActiveCPUs="/sys/fs/cgroup/cpuset/cpuset.effective_cpus">
<CFELSEIF FileExists("/sys/fs/cgroup/docker/cpuset.cpus.effective")>
	<CFSET ActiveCPUs="/sys/fs/cgroup/docker/cpuset.cpus.effective">
<CFELSEIF FileExists("/sys/fs/cgroup/cpuset.cpus.effective")>
	<CFSET ActiveCPUs="/sys/fs/cgroup/cpuset.cpus.effective">
</CFIF>

<!--- Locate total CPU file --->
<CFSET TotalCPUs="">
<CFIF FileExists("/sys/devices/system/cpu/online")>
	<CFSET TotalCPUs="/sys/devices/system/cpu/online">
</CFIF>

<CFSET DockerInfo.ActiveCPUsFile=ActiveCPUs>
<CFSET DockerInfo.TotalCPUsFile=TotalCPUs>
<CFSET DockerInfo.CPU=StructNew()>
<CFSET DockerInfo.CPU.Total=CountRange(StripCRLF(ReadFile(TotalCPUs))," ")>
<CFSET DockerInfo.CPU.Assigned=CountRange(StripCRLF(ReadFile(ActiveCPUs))," ")>

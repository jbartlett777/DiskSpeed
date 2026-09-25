<CFIF Drive.UNRAIDSlot EQ "">
	<CFSET Label=DriveID>
<CFELSE>
	<CFSET Label=Drive.UNRAIDSLot & " (#DriveID#)">
</CFIF>

<CFOUTPUT>
#TS()# Performing random seek tests<br>
<script language="JavaScript">parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Performing random seek tests on #Label#';</script>
</CFOUTPUT>
<CFFLUSH>

<!--- <CFSET OutDir=PersistDir & "/driveinfo/" & Drive.Config.SaveDir> --->

<CFSET Cmd="echo 0 > #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "/usr/bin/ioping -RB -w 10 /dev/#DriveID# > #OutDir#/RandomSeek.txt" & Chr(10) &
		   "rm #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "chmod 666 #OutDir#/RandomSeek.txt" & Chr(10)>
<CFFILE action="write" file="#OutDir#/RandomSeek.sh" mode="766" output="#Cmd#" addnewline="NO">
<cfexecute name="#OutDir#/RandomSeek.sh" timeout="90" />
<!--- <cfexecute name="/usr/bin/ioping" arguments="-RB -w 10 /dev/#DriveID#" variable="RandomSeek"  timeout="90" /> --->
<CFFILE action="read" file="#OutDir#/RandomSeek.txt" variable="RandomSeek">
<CFSET RandomSeek=ListFirst(StripCRLF(RandomSeek)," ")>

<!---
712 requests completed in 9.97 s, 2.78 MiB read, 71 iops, 285.6 KiB/s
generated 713 requests in 10.0 s, 2.79 MiB, 71 iops, 285.1 KiB/s
min/avg/max/mdev = 2.89 ms / 14.0 ms / 24.2 ms / 3.84 ms
root@38344df5f67f:/# ioping -RB -w 10 /dev/sdd
709 9993579786 71 290593 3289695 14095317 24285982 3962752 710 10015118329
--->

<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET CheckSessionID=Session.RequestID>
</cflock>
<CFIF CheckSessionID NEQ SessionID>
	<cfexit method="exittemplate">
</CFIF>

<CFOUTPUT>
#TS()# Performing sequential seek tests<br>
<script language="JavaScript">parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Performing sequential seek tests on #Label#';</script>
</CFOUTPUT>
<CFFLUSH>

<CFSET Cmd="echo 0 > #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "/usr/bin/ioping -RLB -w 2 /dev/#DriveID#" & Chr(10) &
		   "/usr/bin/ioping -RLB -w 10 /dev/#DriveID# > #OutDir#/SequentialSeek.txt" & Chr(10) &
		   "rm #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "chmod 666 #OutDir#/SequentialSeek.txt" & Chr(10)>
<CFFILE action="write" file="#OutDir#/SequentialSeek.sh" mode="766" output="#Cmd#" addnewline="NO">
<!---
<cfexecute name="/usr/bin/ioping" arguments="-RLB -w 2 /dev/#DriveID#" variable="SequentialSeek"  timeout="90" />
<cfexecute name="/usr/bin/ioping" arguments="-RLB -w 10 /dev/#DriveID#" variable="SequentialSeek"  timeout="90" />
--->
<cfexecute name="#OutDir#/SequentialSeek.sh" timeout="90" />
<CFFILE action="read" file="#OutDir#/SequentialSeek.txt" variable="SequentialSeek">
<CFSET SequentialSeek=ListFirst(StripCRLF(SequentialSeek)," ")>


<!---
--- /dev/sdb (block device 7.28 TiB) ioping statistics ---
7.24 k requests completed in 9.78 s, 1.77 GiB read, 740 iops, 185.1 MiB/s
generated 7.24 k requests in 10.0 s, 1.77 GiB, 723 iops, 181.0 MiB/s
min/avg/max/mdev = 972.7 us / 1.35 ms / 43.1 ms / 1.50 ms
root@38344df5f67f:/# ioping -RLB -w 10 /dev/sdb
7266 9772905656 743 194899897 970366 1345019 27562393 1424464 7267 10000255174
--->


<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET CheckSessionID=Session.RequestID>
</cflock>
<CFIF CheckSessionID NEQ SessionID>
	<cfexit method="exittemplate">
</CFIF>


<CFOUTPUT>
#TS()# Performing drive latency tests<br>
<script language="JavaScript">parent.document.getElementById('#ControllerID#').innerHTML='#ContName#: Performing drive latency tests on #Label#';</script>
</CFOUTPUT>
<CFFLUSH>

<CFSET Cmd="echo 0 > #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "/usr/bin/ioping -BDL -c 11 /dev/#DriveID# > #OutDir#/DriveLatency.txt" & Chr(10) &
		   "rm #SaveDir#/pids/$BASHPID" & Chr(10) &
		   "chmod 666 #OutDir#/DriveLatency.txt" & Chr(10)>
<CFFILE action="write" file="#OutDir#/DriveLatency.sh" mode="766" output="#Cmd#" addnewline="NO">
<cfexecute name="#OutDir#/DriveLatency.sh" timeout="90" />
<!--- <cfexecute name="/usr/bin/ioping" arguments="-BDL -c 11 /dev/#DriveID#" variable="DriveLatency"  timeout="90" /> --->
<CFFILE action="read" file="#OutDir#/DriveLatency.txt" variable="DriveLatency">
<CFSET DriveLatency=ListGetAt(StripCRLF(DriveLatency),6," ")>


<!---
--- /dev/sdb (block device 7.28 TiB) ioping statistics ---
10 requests completed in 20.7 ms, 2.50 MiB read, 482 iops, 120.7 MiB/s
generated 11 requests in 10.0 s, 2.75 MiB, 1 iops, 281.6 KiB/s
min/avg/max/mdev = 1.14 ms / 2.07 ms / 10.4 ms / 2.77 ms
root@38344df5f67f:/# ioping -BDL -c 11 /dev/sdb
10 11478533 871 228377616 1119727 1147853 1178854 15869 11 10001228594

--->

<cflock type="readonly" scope="Session" throwontimeout="true" timeout="30">
	<CFSET CheckSessionID=Session.RequestID>
</cflock>
<CFIF CheckSessionID NEQ SessionID>
	<cfexit method="exittemplate">
</CFIF>


<cfoutput>
Random Seek: #RandomSeek#<br>
SequentialSeek: #SequentialSeek#<br>
DriveLatency: #DriveLatency#<br>
</cfoutput>

<CFFILE action="write" file="#OutDir#/latency.txt" output="#RandomSeek#|#SequentialSeek#|#DriveLatency#" addnewline="NO" mode="666">

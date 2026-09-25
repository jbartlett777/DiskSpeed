<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
	<CFSET HWTree=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/usbtree.json" variable="json">
	<CFSET USBTree=DeserializeJSON(json)>
	<CFFILE action="Read" file="#PersistDir#/HideDriveIDs.txt" variable="DeviceIDsToRemove">
<CFELSE>
	<CFABORT>
</CFIF>

<!--- Check to see if we have drives mounted that are not in our config --->
<CFSET NewDrivesFound=0>
<CFSET NewDrivesList="">
<cfexecute name="/bin/ls" arguments="-l /sys/block" variable="BlockDevices"  timeout="90" />
<!--- <cfoutput><pre>#BlockDevices#</pre></cfoutput> --->
<CFLOOP index="i" from="2" to="#ListLen(BlockDevices,Chr(10))#">
	<CFSET CurrLine=ListGetAt(BlockDevices,i,Chr(10))>
	<CFIF FindNoCase("virtual",CurrLine) EQ 0>
		<CFSET DevicePath=ListLast(CurrLine,">")>
		<CFIF FindNoCase("usb",DevicePath) EQ 0>
			<CFSET DevicePath="/sys/" & ListDeleteAt(DevicePath,1,"/")>
			<CFSET tmp=REMatchNoCase("[0-9a-z]{2,4}:[0-9a-z]{2}:[0-9a-z]{2}.[0-9a-z]",DevicePath)>
			<CFIF ArrayLen(tmp) GT 0>
				<CFSET Key=tmp[ArrayLen(tmp)]>
				<CFSET DeviceID=ListLast(DevicePath,"/")>
				<CFIF StructKeyExists(Ref.DriveID,DeviceID) EQ "NO" AND ListFindNoCase("sr",Left(DeviceID,2)) EQ 0>
					<!--- <CFOUTPUT>Not found: #DeviceID#<br></CFOUTPUT> --->
					<CFIF ListFindNoCase(DeviceIDsToRemove,DeviceID) EQ "NO">
						<CFSET NewDrivesFound=NewDrivesFound + 1>
						<CFSET NewDrivesList=ListAppend(NewDrivesList,DeviceID)>
					</CFIF>
				</CFIF>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>

<CFINCLUDE TEMPLATE="Styles.cfm">

<CFSET NeedsOpt=0>
<!--- <CFIF URL.Opt2 EQ "Y">
	<CFINCLUDE TEMPLATE="CheckDriveOpt2.cfm">
<CFELSEIF URL.Opt3 EQ "Y">
	<CFINCLUDE TEMPLATE="CheckDriveOpt3.cfm">
<CFELSE>
	<CFINCLUDE template="CheckDriveOpt.cfm">
</CFIF> --->
<CFIF NeedsOpt EQ 0 AND NewDrivesFound GT 0>
	<CFOUTPUT>
	<body>
	<span class="Bold">#NewDrivesFound# new drive<CFIF NewDrivesFound GT 1>s</CFIF> detected. (#Replace(NewDrivesList,",",", ","ALL")#)</span><br><br>
	<form action="index.cfm" target="_parent" method="POST">
	<input type="Hidden" name="ScanControllers" value="Y">
	<input type="Submit" name="SubmitButton" value="Rescan Controllers">
	</form>
	</CFOUTPUT>
</CFIF>

<CFINCLUDE template="DispBusTree.cfm">

<CFOUTPUT>
<!--- <small>A <span class="red">red outline</span> around a drive indicates drive activity (updates every 5 seconds)</small><br> --->
<br>
<form action="Benchmark.cfm" target="_parent" method="GET">
<input type="Submit" value="Benchmark Drives">
</form>
<!---<button onclick="window.location.href='Benchmark.cfm'">Benchmark Drives</button>&nbsp;&nbsp;&nbsp;--->
<!--- <button onclick="window.location.href='FindOptimalBlockSize.cfm'">Test Drives for Optimal Block Size</button><br> --->
<br>
</CFOUTPUT>

<CFINCLUDE TEMPLATE="DispBenchmarkGraphs.cfm">

<CFOUTPUT>
<span class="Size14">
DiskSpeed was created as a hobby/passion project to help myself &amp; others to better monitor the health of their drives and the data they
contain and is shared free of charge. If you've found benefit in this application or it saved your bacon from the bit bucket, please
consider <a href="https://www.buymeacoffee.com/jbartlett0" target="_blank">buying me a coffee or two</a>.<br>
<br><hr><br>
<b>Please Note:</b><br>
If your drive image is not detected, please check the following:<br>
1. Check to see if the Brand name is included in the Model string. If so, please contact me with the details.<br>
2. Check to see if there's some extra information included before or after the actual model number. Contact me with the details
   as I will need to add code to remove it.<br>
3. Please check my <a href="#StrangeJourney#/hddb/" target="_blank">Hard Drive Database</a> to see if
   your model is listed but under a different format. Contact me with the details if so.<br>
4. Some SSD drives do not report a Vendor. This will require a manual correction in the future.<br>
<a href="mailto:harddrivedb@gmail.com?subject=HD%20DB">Email John Bartlett</a><br>
<br>
Missing models are recorded for my review and you can try rescanning later to see if they've been added.<br>
Alternately, you can check the <a href="#StrangeJourney#/hddb.cfm?View=images" target="_blank">Brand Image Database</a> to see if
there's a template image for you to use or if you have a drive image you'd prefer to use, edit the drive and upload it.<br>
</span>
</body>
</html>
</CFOUTPUT>

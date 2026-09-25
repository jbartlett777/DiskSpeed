<CFSET SaveDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>

<CFPARAM name="FORM.Drive" default="">
<CFIF FORM.Drive NEQ "">
	<CFSET URL.Drive=FORM.Drive>
</CFIF>

<CFPARAM name="URL.iSMARTToggle" default="">
<CFPARAM name="SMARTToggle" default="#URL.iSmartToggle#">

<CFIF ListFind("Y,N",URL.iSMARTToggle)>
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#SaveDir#/SMARTToggle.txt" output="#URL.iSMARTToggle#" addnewline="NO">
	</cflock>
</CFIF>

<CFIF FileExists("#SaveDir#/SMARTToggle.txt")>
	<CFFILE action="read" file="#SaveDir#/SMARTToggle.txt" variable="SMARTToggle">
<CFELSE>
	<CFSET SMARTToggle="N">
</CFIF>
<CFSET SMARTDispFields="Reallocated_Sector_Ct,Power_On_Hours,Reallocated_Event_Count,Current_Pending_Sector,Offline_Uncorrectable,UDMA_CRC_Error_Count," &
					   "Runtime_Bad_Block,Reported_Uncorrect,High_Fly_Writes,Total_LBAs_Written,Total_LBAs_Read," &
					   "Available Spare,Percentage Used,Data Units Read,Data Units Written,Media and Data Integrity Errors,Power On Hours,Helium_Level," &
					   "Wear_Leveling_Count,Used_Rsvd_Blk_Cnt_Tot,Erase_Fail_Count_Total,Erase_Fail_Count,Lifetime_Writes_GiB,Lifetime_Reads_GiB">
<CFSET SMART=QueryNew("Desc,Data","varchar,varchar")>
<CFSET DriveInStandBy="">
<CFIF HW[Key].Ports[PortNo].Attrib.USB EQ 0>
	<CFIF FileExists("#SaveDir#/smartreport.wddx")>
		<CFFILE action="read" file="#SaveDir#/smartreport.wddx" variable="wddx">
		<cfwddx input="#wddx#" output="SmartReport" action="wddx2cfml">
	<CFELSE>
		<CFSET SMARTReport=QueryNew("DateStamp,Desc,Data","date,varchar,varchar")>
	</CFIF>
	<!--- Fetch smart info from UNRAID --->
	<CFSET SMARTData="">
	<CFSET SMARTStatus="">
	<CFSET DescList="">
	<CFIF DirectoryExists("\var\local\emhttp\smart")>
		<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ "">
			<CFSET FN=HW[Key].Ports[PortNo].UNRAIDSlotSrc>
		<CFELSE>
			<CFSET FN=HW[Key].Ports[PortNo].DriveID>
		</CFIF>
		<CFIF FileExists("\var\local\emhttp\smart\#FN#")>
			<CFFILE action="Read" file="\var\local\emhttp\smart\#FN#" variable="SmartData">
			<CFDIRECTORY action="list" directory="\var\local\emhttp\smart" filter="#FN#" name="Dir">
			<CFSET SMARTDate=Dir.DateLastModified>
		</CFIF>
		<CFIF FileExists("\var\local\emhttp\smart\#FN#.ssa")>
			<CFFILE action="Read" file="\var\local\emhttp\smart\#FN#.ssa" variable="SmartStatus">
		</CFIF>
		<CFIF FindNoCase("Device is in STANDBY mode",SmartData)>
			<CFSET DriveInStandBy="Y">
		<CFELSE>
			<CFSET DriveInStandBy="N">
			<!--- Check to see if we have SMART ID values listed --->
			<CFSET StartLine=0>
			<CFSET CurrLineID=0>
			<CFSET NoSMARTIDs=0>
			<CFSET ValueStart=0>
			<CFLOOP index="CurrLine" list="#SmartData#" delimiters="#Chr(10)#">
				<CFSET CurrLineID=CurrLineID+1>
				<CFIF FindNoCase("RAW_VALUE",CurrLine)>
					<CFSET ValueStart=FindNoCase("RAW_VALUE",CurrLine)>
				</CFIF>
				<CFIF Left(CurrLine,4) EQ "ID## ">
					<CFSET StartLine=CurrLineID+1>
				<CFELSE>
					<CFIF StartLine GT 0>
						<CFIF IsNumeric(ListFirst(CurrLine," ")) EQ "NO">
							<CFSET NoSMARTIDs=1>
							<CFBREAK>
						</CFIF>
					</CFIF>
				</CFIF>
			</CFLOOP>
			<CFIF StartLine EQ 0>
				<CFSET NoSmartIDs=1>
				<CFIF FileExists("#SaveDir#/smartdatanonstandard.txt") EQ "NO">
					<CFFILE action="write" file="#SaveDir#/smartdatanonstandard.txt" addnewline="NO" output="" mode="666">
				</CFIF>
			</CFIF>
			<!--- Check to see if we've already logged this entry --->
			<CFQUERY name="CheckDate" dbtype="Query">
				SELECT MAX(DateStamp) as DateStamp
				FROM SMARTReport
			</CFQUERY>
			<CFPARAM name="variables.SMARTDate" default="">
			<CFIF CheckDate.DateStamp NEQ SMARTDate>
				<CFSET InData=0>
				<CFSET CurrLineID=0>
				<CFLOOP index="CurrLine" list="#SMARTData#" delimiters="#Chr(10)#">
					<CFSET CurrLineID=CurrLineID+1>
					<CFIF NoSMARTIDs>
						<CFIF InData>
							<CFIF ListLen(CurrLine,":") EQ 2>
								<CFSET SMARTDesc=Trim(ListFirst(CurrLine,":"))>
								<CFSET SMARTValue=Trim(ListLast(CurrLIne,":"))>
								<CFSET DescList=ListAppend(DescList,SMARTDesc,"|")>
								<!--- Only log if the data has changed --->
								<CFQUERY name="CheckData" dbtype="Query">
									SELECT TOP 1 Data
									FROM SMARTReport
									WHERE Desc='#SMartDesc#'
									ORDER BY DateStamp DESC
								</CFQUERY>

								<CFIF CheckData.Data NEQ SMARTValue>
									<CFSET QueryAddRow(SMARTReport)>
									<CFSET QuerySetCell(SMARTReport,"DateStamp",SMARTDate)>
									<CFSET QuerySetCell(SMARTReport,"Desc",SMARTDesc)>
									<CFSET QuerySetCell(SMARTReport,"Data",SMARTValue)>
								</CFIF>
							</CFIF>
						</CFIF>
					<CFELSE>
						<CFIF CurrLineID GTE StartLine>
							<CFSET SMARTID=Trim(ListFirst(CurrLine," "))>
							<CFSET SMARTDesc=ListGetAt(CurrLine,2," ")>
							<CFSET SMARTValue=Mid(CurrLine,ValueStart,Len(CurrLine))>
							<CFSET DescList=ListAppend(DescList,SMARTDesc,"|")>
							<!--- Only log if the data has changed --->
							<CFQUERY name="CheckData" dbtype="Query">
								SELECT TOP 1 Data
								FROM SMARTReport
								WHERE Desc='#SMartDesc#'
								ORDER BY DateStamp DESC
							</CFQUERY>
							<CFIF CheckData.Data NEQ SMARTValue>
								<CFSET QueryAddRow(SMARTReport)>
								<CFSET QuerySetCell(SMARTReport,"DateStamp",SMARTDate)>
								<CFSET QuerySetCell(SMARTReport,"Desc",SMARTDesc)>
								<CFSET QuerySetCell(SMARTReport,"Data",SMARTValue)>
							</CFIF>
						</CFIF>
					</CFIF>
					<CFIF FindNoCase("START OF READ SMART DATA",CurrLine)
					   OR FindNoCase("START OF SMART DATA",CurrLine)>
						<CFSET InData=1>
					</CFIF>
				</CFLOOP>
			</CFIF>
		</CFIF>
	</CFIF>

	<CFIF DescList NEQ "" AND FileExists("#SaveDir#/SMARTDescList.txt") EQ "NO">
		<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
			<CFFILE action="write" file="#SaveDir#/SMARTDescList.txt" output="#DescList#" addnewline="NO" mode="666">
		</cflock>
	</CFIF>
	<cfwddx input="#SmartReport#" output="wddx" action="cfml2wddx">
	<cflock name="WriteCheck" timeout="30" throwontimeout="yes" type="exclusive">
		<CFFILE action="write" file="#SaveDir#/smartreport.wddx" output="#wddx#" addnewline="NO" mode="666">
	</cflock>

	<!--- Build most recent SMART data --->
	<CFIF FileExists("#SaveDir#/SMARTDescList.txt")>
		<CFFILE action="read" file="#SaveDir#/SMARTDescList.txt" variable="DescList">
	</CFIF>
	<CFLOOP index="CurrDesc" list="#DescList#" delimiters="|">
		<CFQUERY name="ValueList" dbtype="Query">
			SELECT TOP 1 *
			FROM SMARTReport
			WHERE Desc='#CurrDesc#'
			ORDER BY DateStamp DESC
		</CFQUERY>
		<CFSET QueryAddRow(SMART)>
		<CFSET QuerySetCell(SMART,"Desc",CurrDesc)>
		<CFSET QuerySetCell(SMART,"Data",ValueList.Data)>
	</CFLOOP>

	<!--- <cfdump var=#SMARTReport#>
	<cfdump var=#SMART#> --->
</CFIF>


<CFSET ThumbCSS=CSSName(HW[Key].Ports[PortNo].Config.SaveDir)>

<CFOUTPUT>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td valign="top">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td class="#ThumbCSS#_td" id="#HW[Key].Ports[PortNo].DriveID#_image" valign="top">
						<div class="#ThumbCSS#" id="#HW[Key].Ports[PortNo].DriveID#_text">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#</div>
					</td>
				</tr>
			</table>
		</td>
		<td width="1">&nbsp;</td>
		<td class="Details NOBR" width="#HW[Key].Ports[PortNo].Config.ImageWidth#" valign="top">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td valign="top" class="Details NOBR">
						<span class="Bold">Drive ID:</span> #HW[Key].Ports[PortNo].DriveID#
						<CFIF HW[Key].Ports[PortNo].UNRAIDSlot NEQ "">
							(#EncodeForHTML(HW[Key].Ports[PortNo].UNRAIDSlot)#)
						</CFIF>
						<br>
						<span class="Bold">Vendor:</span> #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Vendor)#&nbsp;&nbsp;<CFIF HW[Key].Ports[PortNo].HDDBFound EQ 0 AND HW[Key].USB EQ 0>[<span class="Underline Hand" onClick="document.getElementById('UpdateVendor').style.display='block';">change</span>]</CFIF><br>
						<span class="Bold">Model:</span> #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Model)#<br>
						<span class="Bold">Serial Number:</span> #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Serial)#<br>
					</td>
					<td width="1">&nbsp;</td>
					<CFIF NoEdit EQ "N">
						<td valign="top" class="NOBR" id="UpdateVendor" style="display:none">
							<form action="/isolated/UpdateVendor.cfm" method="POST">
								<input type="Hidden" name="Drive" value="#URL.Drive#">
								<span class="Size14 Bold">New Vendor:</span><br>
								<input type="text" id="NewVendorField" name="NewVendor" value="#HW[Key].Ports[PortNo].Attrib.Vendor#">
								<input type="submit" value="Save">
								<input type="button" value="Cancel" onclick="document.getElementById('NewVendorField').value='#EncodeForJavascript(HW[Key].Ports[PortNo].Attrib.Vendor)#';document.getElementById('UpdateVendor').style.display='none';" />
							</form>
						</td>
					</CFIF>
				</tr>
			</table>
			<span class="Bold">Revision:</span> #EncodeForHTML(HW[Key].Ports[PortNo].Attrib.Rev)#<br>
			<span class="Bold">Capacity:</span> #HW[Key].Ports[PortNo].Attrib.Size.DispSize#<br>
			<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.RPM GT 0>
				<span class="Bold">RPM:</span> #HW[Key].Ports[PortNo].Attrib.Configuration.RPM#<br>
			</CFIF>
			<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeedDisp NEQ "">
				<span class="Bold">Signaling Speed:</span> #HW[Key].Ports[PortNo].Attrib.Configuration.SignalingSpeedDisp#<br>
			</CFIF>
			<CFIF Left(HW[Key].Ports[PortNo].DriveID,4) EQ "nvme">
				<span class="Bold">Sector Size:</span> #HW[Key].Ports[PortNo].Attrib.configuration.sectorsize#<br>
			<CFELSE>
				<span class="Bold">Logical/Physical Sector Size:</span> #HW[Key].Ports[PortNo].Attrib.configuration.logicalsectorsize#/#HW[Key].Ports[PortNo].Attrib.configuration.sectorsize#<br>
			</CFIF>
			<CFIF ListFindNoCase("?|?,0|0,1|1","#HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current#|#HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current#") EQ 0>
				<CFIF HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current EQ HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current>
					<span class="Bold">Multiple Sector Transfer:</span> #HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current# (Current &amp; Max)<br>
				<CFELSE>
					<span class="Bold">Multiple Sector Transfer:</span> #HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current# (Current) / #HW[Key].Ports[PortNo].Attrib.Configuration.MultipleSectorTransfer.Current# (Max)<br>
				</CFIF>
			</CFIF>
			<CFIF HW[Key].Ports[PortNo].Attrib.PlatterCnt NEQ 0>
				<span class="Bold">Platters/Heads:</span> #HW[Key].Ports[PortNo].Attrib.PlatterCnt#/#HW[Key].Ports[PortNo].Attrib.HeadCnt#<br>
			</CFIF>
			<CFIF StructKeyExists(HW[Key].Ports[PortNo],"SSD_Benchmark")>
				<CFIF StructKeyExists(HW[Key].Ports[PortNo].SSD_Benchmark,"CacheDetected")>
					<CFSET Bench=Duplicate(HW[Key].Ports[PortNo].SSD_Benchmark)>
					<span class="Bold">Read Speed:</span>
					<CFIF KBytes(Bench.ReadMin,"9.9") EQ KBytes(Bench.ReadMax,"9.9")>
						#KBytes(Bench.ReadMin,"9.9")#<br>
					<CFELSE>
						#ListFirst(KBytes(Bench.ReadMin,"9.9")," ")# -
						#KBytes(Bench.ReadMax,"9.9")#/Sec,
						#KBytes(Bench.ReadAvg,"9,999.9")#/Sec Avg<br>
					</CFIF>
					<CFIF HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetected EQ 1>
						<span class="Bold">Burst Write Speed:</span>
						<!---
						<CFIF KBytes(Bench.WriteMin,"9.9") EQ KBytes(Bench.WriteMax,"9.9")>
							#KBytes(Bench.WriteMin,"9.9")#<br>
						<CFELSE>
							#ListFirst(KBytes(Bench.WriteMin,"9.9")," ")# -
							#KBytes(Bench.WriteMax,"9.9")#/Sec,
							#KBytes(Bench.WriteAvg,"9.9")#/Sec Avg<br>
						</CFIF>
						--->
						#KBytes(Bench.WriteMax,"9.9")#/Sec,<br>

						<span class="Bold">Sustained Write Speed:</span>
						#KBytes(Bench.WriteAvg,"9.9")#/Sec Avg<br>
					<CFELSE>
						<span class="Bold">Write Speed:</span>
						<CFIF Bench.WriteMin GT 0>
							#ListFirst(KBytes(Bench.WriteMin,"9.9")," ")# -
							#KBytes(Bench.WriteMax,"9.9")#/Sec,
						</CFIF>
						#KBytes(Bench.WriteAvg,"9.9")#/Sec Avg<br>
					</CFIF>
					<CFIF StructKeyExists(HW[Key].Ports[PortNo],"TrimSupported")>
						<span class="Bold">Trim Supported:</span> #YesNo(HW[Key].Ports[PortNo].TrimSupported)#<br>
					</CFIF>
					<!---
					<CFIF HW[Key].Ports[PortNo].SSD_Benchmark.CacheDetectedAt EQ 1>
						<b>Note:</b> Drive cache was detected but exceeded in the first write test.<br>
						A <a href="Benchmark.cfm" target="_parent">manual benchmark</a> on just this drive with a smaller test file may<br>
						yield better information.<br>
					</CFIF>
					--->
				</CFIF>
			</CFIF>
		</td>
		<td>&nbsp;&nbsp;</td>
		<CFPARAM name="variables.DoNotDisplaySMARTInfo" default="">
		<CFIF DoNotDisplaySMARTInfo EQ "">
			<td valign="top">
				<table border="0" cellpadding="0" cellspacing="0">
				<!--- <CFIF DriveInStandBy EQ "Y">
					<tr><td class="Details NOBR Bold" colspan="3">Drive is spun down</td></tr>
				</CFIF> --->
				<CFIF SMART.RecordCount GT 0>
					<tr>
						<td class="Details NOBR">SMART Data as of</td>
						<td>&nbsp;&nbsp;&nbsp;</td>
						<td class="Details NOBR">#DateFormat(SMARTDate,"mmm d, yyyy")# #TimeFormat(SMARTDate,"h:mm tt")#</td>
					</tr>
					<CFSET TempRow="">
					<CFLOOP index="CR" from="1" to="#SMART.RecordCount#">
						<CFIF FindNoCase("Temperature",SMART.Desc[CR])>
							<CFSET TempRow=ListAppend(TempRow,CR)>
							<tr>
								<td class="Details NOBR">#Replace(SMART.Desc[CR],"_"," ","ALL")#</td>
								<td></td>
								<td class="Details NOBR">#SMART.Data[CR]#</td>
							</tr>
						</CFIF>
					</CFLOOP>
					<CFLOOP index="CR" from="1" to="#SMART.RecordCount#">
						<CFSET ExtraData="">
						<CFIF ListFindNoCase("Total_LBAs_Written,Total_LBAs_Read",SMART.Desc[CR]) AND IsNumeric(SMART.Data[CR])>
							<CFSET QuerySetCell(SMART,"Data",KBytes(SMART.Data[CR] * HW[Key].Ports[PortNo].Attrib.Configuration.LogicalSectorSize),CR)>
						</CFIF>
						<CFIF ListFindNoCase("Power_On_Hours",SMART.Desc[CR]) AND IsNumeric(SMART.Data[CR])>
							<CFSET D=int(SMART.Data[CR]/24)>
							<CFSET H=SMART.Data[CR] - D*24>
							<CFSET ExtraData=" [">
							<CFIF D GT 365>
								<CFSET Y=int(D/365)>
								<CFSET D=D-Y * 365>
								<CFSET ExtraData=ExtraData & "#Y# Year" & s(Y) & ", ">
							</CFIF>
							<CFSET ExtraData=ExtraData & "#D# Day" & s(D)>
							<CFIF H GT 0>
								<CFSET ExtraData=ExtraData & ", #H# hour" & s(H)>
							</CFIF>
							<CFSET ExtraData=ExtraData & "]">
						</CFIF>
						<CFIF ListFind(TempRow,CR) EQ 0>
							<CFIF ListFindNoCase(SMARTDispFields,SMART.Desc[CR])>
								<tr>
									<td class="Details NOBR">#Replace(SMART.Desc[CR],"_"," ","ALL")#</td>
									<td></td>
									<td class="Details NOBR">#SMART.Data[CR]##ExtraData#</td>
								</tr>
							<CFELSE>
								<CFIF SMARTToggle EQ "Y">
									<tr>
										<td class="Details NOBR">#Replace(SMART.Desc[CR],"_"," ","ALL")#</td>
										<td></td>
										<td class="Details NOBR">#SMART.Data[CR]##ExtraData#</td>
									</tr>
								</CFIF>
							</CFIF>
						</CFIF>
					</CFLOOP>
					<tr>
						<CFIF SMARTToggle EQ "Y">
							<td colspan="3" class="Details NOBR"><a href="DispDrive.cfm?Drive=#URLEncodedFormat(URL.Drive)#&iSMARTToggle=N"><img src="images/ToggleOn.png" width="27" height"13" border="0"></a> Show all SMART Data</td>
						<CFELSE>
							<td colspan="3" class="Details NOBR"><a href="DispDrive.cfm?Drive=#URLEncodedFormat(URL.Drive)#&iSMARTToggle=Y"><img src="images/ToggleOff.png" width="27" height"13" border="0"></a> Show all SMART Data</td>
						</CFIF>
					</tr>
				</CFIF>
				</table>
			</td>
		</CFIF>
	</tr>
</table>
<br>
</CFOUTPUT>

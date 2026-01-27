<CFSET JSONDir="C:\inetpub\strangejourney.net\SMARTJson">

<CFDIRECTORY action="list" directory="#JSONDir#" name="Files" sort="datelastmodified asc" type="file">



<CFLOOP index="CR" from="1" to="#Files.RecordCount#">
	<CFIF ListLast(Files.Name[CR],".") EQ "zip">
		<CFOUTPUT>#TS()# Processing #Files.Name[CR]#<br></CFOUTPUT><CFFLUSH>
		<CFZIP action="read" file="#JSONDir#/#Files.Name[CR]#" entrypath="smartdata.json" variable="json"></CFZIP>
		<CFSET FileDate=CreateDate(ListGetAt(Files.Name[CR],1,"-"),ListGetAt(Files.Name[CR],2,"-"),ListFirst(ListGetAt(Files.Name[CR],3,"-"),"_"))>
		<CFSET SMART=DeserializeJSON(json)>

		<!--- Loop over devices --->
		<CFLOOP index="ID" list="#StructKeyList(SMART)#">
			<!--- Oops, forgot bytes for nvme --->
			<CFIF StructKeyExists(SMART[ID],"bytes") EQ "NO">
				<CFSET SMART[ID].bytes=0>
			</CFIF>
			<!--- Gather SMART Info --->
			<CFSET Labels="">
			<CFIF StructKeyExists(SMART[ID],"smart")>
				<CFIF SMART[ID].nvme EQ 0>
					<!--- Spinners --->
					<CFLOOP index="i" from="1" to="#ArrayLen(SMART[ID].smart)#">
						<CFSET CurrLabel=SMART[ID].smart[i].id & "|" & SMART[ID].smart[i].name>
						<CFSET Labels=ListAppend(Labels,CurrLabel)>
					</CFLOOP>
				<CFELSE>
					<!--- NVME Drives --->
					<CFLOOP index="CurrLabel" list="#StructKeyList(SMART[ID].smart)#">
						<CFIF ListFindNoCase("mn,sn,vid,ssvid",CurrLabel) EQ 0>
							<CFSET Labels=ListAppend(Labels,CurrLabel)>
						</CFIF>
					</CFLOOP>
				</CFIF>
				<CFSET LabelHash=Hash(Labels)>
				<!--- Check to see if this SMART layout has been stored, add if not --->
				<CFQUERY name="Chk" datasource="MySQL">
					SELECT id
					FROM diskspeed.smart_labels 
					WHERE version=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#LabelHash#">
				</CFQUERY>
				<CFIF Chk.RecordCount EQ 0>
					<CFQUERY datasource="MySQL" Result="Result">
						INSERT INTO diskspeed.smart_labels (version,labels)
						VALUES (<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#LabelHash#">,
						<cfqueryparam CFSQLType="CF_SQL_LONGVARCHAR" value="#Labels#">)
					</CFQUERY>
					<CFSET SmartLabelID=Result.generatedKey>
				<CFELSE>
					<CFSET SmartLabelID=Chk.id>
				</CFIF>
			</CFIF>
			<!--- Look to see if the drive is in the DB --->
			<CFQUERY name="Drive" datasource="MySQL">
				SELECT *
				FROM diskspeed.drive_smart
				WHERE DriveID1=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Left(ID,4)#">
				  AND DriveID2=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Mid(ID,5,4)#">
				  AND DriveID3=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Right(ID,32)#">
			</CFQUERY>
			<CFIF Drive.RecordCount EQ 0>
				<CFSET NoSMART=0>
				<CFSET PowerOnHours=0>
				<CFIF StructKeyExists(SMART[ID],"smart")>
					<!--- Get initial power on hours --->
					<CFSET PowerOnHours=0>
					<CFIF SMART[ID].nvme EQ 0>
						<CFLOOP index="i" from="1" to="#ArrayLen(SMART[ID].smart)#">
							<CFIF SMART[ID].smart[i].id EQ 9>
								<CFSET PowerOnHours=Val(SMART[ID].smart[i].value)>
								<CFBREAK>
							</CFIF>
						</CFLOOP>
					<CFELSE>
						<CFIF StructKeyExists(SMART[ID].smart,"power_on_hours")>
							<CFSET PowerOnHours=SMART[ID].smart.power_on_hours>
						</CFIF>
					</CFIF>
					<!--- Check for missing values from beta versions --->
					<CFLOOP index="Chk" list="SSD,Model,Rev,Bytes">
						<CFIF StructKeyExists(SMART[ID],Chk) EQ "NO">
							<CFSET SMART[ID][Chk]="">
						</CFIF>
					</CFLOOP>
				<CFELSE>
					<CFSET NoSMART=1>
					<CFSET SmartLabelID=0>
				</CFIF>
				<CFLOOP index="Chk" list="Rev">
					<CFIF StructKeyExists(SMART[ID],Chk) EQ "NO">
						<CFSET SMART[ID][Chk]="">
					</CFIF>
				</CFLOOP>
				<CFQUERY result="Result" datasource="MySQL">
					INSERT INTO diskspeed.drive_smart (DriveID1,DriveID2,DriveID3,LabelID,IsNVME,IsSSD,Model,Rev,Capacity,DateCreated,InitialPowerOnHours,DateUpdated,NoSMART)
					VALUES (
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Left(ID,4)#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Mid(ID,5,4)#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Right(ID,32)#">,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#SmartLabelID#">,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Val(SMART[ID].nvme)#">,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Val(SMART[ID].ssd)#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].Model#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].Rev#">,
						<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Val(SMART[ID].bytes)#">,
						<cfqueryparam CFSQLType="CF_SQL_DATE" value="#CreateODBCDate(FileDate)#">,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Val(PowerOnHours)#">,
						NULL,
						<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#NoSMART#">
					)
				</CFQUERY>
				<CFIF NoSMART EQ 1>
					<CFBREAK>
				</CFIF>
				<CFSET CurrDriveID=Result.generatedKey>
				<CFIF SMART[ID].nvme EQ 0>
					<!--- Process standard SMART --->
					<CFLOOP index="i" from="1" to="#ArrayLen(SMART[ID].smart)#">
						<CFQUERY datasource="MySQL">
							INSERT INTO diskspeed.drive_smart_values (DriveID,SmartID,Normalized,`Value`,`String`)
							VALUES (
								<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrDriveID#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].id#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].normalized#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].value#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].string#">
							)
						</CFQUERY>
					</CFLOOP>
				<CFELSE>
					<!--- Process NVME SMART--->
					<CFLOOP index="Label" list="#StructKeyList(SMART[ID].smart)#">
						<CFQUERY datasource="MySQL">
							INSERT INTO diskspeed.drive_smart_values (DriveID,SmartID,Normalized)
							VALUES (
								<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrDriveID#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Label#">,
								<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[Label]#">
							)
						</CFQUERY>
					</CFLOOP>
				</CFIF>
			<CFELSE>
				<!--- Update Drive --->
				<CFQUERY datasource="MySQL">
					UPDATE diskspeed.drive_smart
					SET DateUpdated=<cfqueryparam CFSQLType="CF_SQL_DATE" value="#CreateODBCDate(FileDate)#">
					<!--- Update values if previously missing --->
					<CFIF Val(SMART[ID].NVME) EQ 1 AND Drive.Capacity EQ 0 AND Val(SMART[ID].bytes) GT 0>
						,Capacity=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].bytes#">
					</CFIF>
					<CFIF StructKeyExists(SMART[ID],"model")>
						<CFIF SMART[ID].model NEQ "" AND Drive.model EQ "">
							,model=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].model#">
						</CFIF>
					</CFIF>
					<CFIF StructKeyExists(SMART[ID],"Rev")>
						<CFIF SMART[ID].Rev NEQ "" AND Drive.Rev EQ "">
							,Rev=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].Rev#">
						</CFIF>
					</CFIF>
					WHERE DriveID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Drive.DriveID#">
				</CFQUERY>
				<CFIF StructKeyExists(SMART[ID],"SMART") EQ "NO">
					<CFBREAK>
				</CFIF>
				<!--- Fetch saved SMART values for drive --->
				<CFQUERY name="SMARTValues" datasource="MySQL">
					SELECT id, SmartID, Normalized, `Value`, `String`
					FROM diskspeed.drive_smart_values
					WHERE DriveID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Drive.DriveID#">
				</CFQUERY>
				<CFIF Val(SMART[ID].NVME) EQ 0>
					<!--- Update standard SMART values --->
					<CFLOOP index="i" from="1" to="#ArrayLen(SMART[ID].smart)#">
						<CFQUERY name="Hist" dbtype="Query">
							SELECT * FROM SMARTValues WHERE SmartID='#SMART[ID].smart[i].id#'
						</CFQUERY>
						<CFIF Hist.RecordCount EQ 0>
							<CFQUERY datasource="MySQL">
								INSERT INTO diskspeed.drive_smart_values (DriveID, SmartID, Normalized, `Value`, `Smart`)
								VALUES (
									<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrDriveID#">,
									<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Label#">,
									<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].Normalized#">,
									<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].Value#">,
									<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].String#">
								)
							</CFQUERY>
						<CFELSE>
							<CFIF SMART[ID].smart[i].normalized NEQ Hist.Normalized
							   OR SMART[ID].smart[i].value NEQ Hist.Value
							   OR SMART[ID].smart[i].string NEQ Hist.String>
								<CFQUERY datasource="MySQL">
									UPDATE diskspeed.drive_smart_values
									SET Normalized=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].normalized#">,
										`Value`=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].value#">,
										`String`=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#SMART[ID].smart[i].string#">
									WHERE ID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Hist.id#">
								</CFQUERY>
							</CFIF>
						</CFIF>
					</CFLOOP>
				<CFELSE>
					<!--- Update NVME SMART values --->
					<CFLOOP index="Key" list="#StructKeyList(SMART[ID].smart)#">
						<!--- Fetch history --->
						<CFQUERY name="Hist" dbtype="Query">
							SELECT * FROM SMARTValues WHERE SmartID=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Key#">
						</CFQUERY>
						<CFIF Hist.RecordCount EQ 0>
							<CFQUERY datasource="MySQL">
								INSERT INTO diskspeed.drive_smart_values (DriveID, SmartID, Normalized)
								VALUES (
									<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#CurrDriveID#">,
									<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Label#">,
									<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#SMART[ID].smart[Key]#">
								)
							</CFQUERY>
						<CFELSE>
						</CFIF>
					</CFLOOP>
				</CFIF>
			</CFIF>
		</CFLOOP>
		
	<CFELSEIF ListLast(Files.Name[CR],".") EQ "txt">
		<CFOUTPUT>#TS()# Processing #Files.Name[CR]#<br></CFOUTPUT><CFFLUSH>
		<!--- Remove drives --->
		<CFFILE action="read" file="#JSONDir#/#Files.Name[CR]#" variable="IDList">
		<CFSET IDList=Replace(StripCR(IDList),Chr(10),"","ALL")>
		<CFLOOP index="ID" list="#IDList#">
			<CFIF Len(ID) EQ 41>
				<CFQUERY name="Chk" datasource="MySQL">
					SELECT DriveID
					FROM diskspeed.drive_smart
					WHERE DriveID1=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Left(ID,4)#">
					AND DriveID2=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Mid(ID,5,4)#">
					AND DriveID3=<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#Right(ID,32)#">
				</CFQUERY>
				<CFIF Chk.RecordCount GT 0>
					<CFQUERY datasource="MySQL">
						DELETE FROM diskspeed.drive_smart_values
						WHERE DriveID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Chk.DriveID#">
					</CFQUERY>
					<CFQUERY datasource="MySQL">
						DELETE FROM diskspeed.drive_smart
						WHERE DriveID=<cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#Chk.DriveID#">
					</CFQUERY>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFIF>
	<CFFILE action="move" source="#JSONDir#/#Files.Name[CR]#" destination="#JSONDir#/Processed/#Files.Name[CR]#">
</CFLOOP>

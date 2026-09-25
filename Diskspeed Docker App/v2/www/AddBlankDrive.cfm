<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>
<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
<CFSET Ref=DeserializeJSON(json)>

<CFSET FORM.Model=Trim(FORM.Model)>
<CFSET ModelDir=Replace(FORM.Model,"/","-","ALL")>
<CFSET ModelDir=Replace(ModelDir,":","-","ALL")>

<!--- Check to see if the model already exists in the set --->
<CFIF StructKeyExists(Ref.Vendor,FORM.Vendor)>
	<CFIF StructKeyExists(Ref.Vendor[FORM.Vendor],FORM.Model)>
		<CFLOCATION URL="index.cfm?DefaultVendor=#FORM.Vendor#&ModelExists=Y&Model=#FORM.Model#&Capacity=#FORM.Capacity#&Clone=#FORM.Clone#" addtoken="NO">
	</CFIF>
</CFIF>

<cflock scope="Application" type="exclusive" timeout="30">
	<CFPARAM name="Application.AllModels" default="">
	<CFSET AllModels=Duplicate(Application.AllModels)>
</cflock>

<!--- Check to see if Model exists --->
<CFIF IsStruct(AllModels) EQ "NO">
	<CFHTTP URL="#StrangeJourney#/diskspeed/ListModels.cfm" method="GET"></CFHTTP>
	<CFIF CFHTTP.Status_Code EQ 200>
		<CFSET AllModels=DeserializeJSON(CFHTTP.FileContent)>
		<cflock scope="Application" type="exclusive" timeout="30">
			<CFSET Application.AllModels=Duplicate(AllModels)>
		</cflock>
	<CFELSE>
		<CFOUTPUT>Error fetching all drive models<br></CFOUTPUT>
		<CFSET AllModels=StructNew()>
	</CFIF>
</CFIF>
<CFPARAM name="FORM.AddAnyway" default="N">
<CFIF FORM.AddAnyway NEQ "Y">
	<CFIF StructKeyExists(AllModels,FORM.Vendor)>
		<CFIF ListFindNoCase(AllModels[FORM.Vendor],FORM.Model)>
			<CFLOCATION URL="index.cfm?DefaultVendor=#FORM.Vendor#&DupeModel=Y&Model=#FORM.Model#&Capacity=#FORM.Capacity#&Clone=#FORM.Clone#" addtoken="NO">
		</CFIF>
	</CFIF>
</CFIF>

<CFIF StructKeyExists(HW,"Create") EQ "NO">
	<CFSET HW["Create"]=StructNew()>
	<CFSET HW.Create.TotalDrives=0>
	<CFSET HW.Create.Ports=ArrayNew(1)>
	<CFSET HW.Create.Type="Storage">
	<CFSET HW.Create.NVMe=0>
	<CFSET HW.Create.USB=0>
	<CFSET HW.Create.Config=StructNew()>
	<CFSET HW.Create.Config.Vendor="Create">
	<CFSET HW.Create.Config.SVendor="Create">
	<CFSET HW.Create.Config.Device="Hard drive holder">
	<CFSET HW.Create.Config.Class="">
</CFIF>

<CFIF FORM.Clone EQ "">
	<cfscript>
	D=StructNew();
	D.DevicePath="Phantom";
	D.ModelHash=CreateUUID();
	D.DriveHash=CreateUUID();
	D.DriveID="zz" & FormatBaseN(ArrayLen(HW.Create.Ports)+1,36);
	D.UNRAIDSlot="";
	D.USB=0;
	D.Partitions=StructNew();
	D.Partitions.PTUUID="";
	D.Partitions.PARTITIONTABLE="";
	D.Partitions.Partitions=ArrayNew(1);
	D.OptimalBlockSize=33554432;
	D.Config.SaveDir=LCase(ModelDir) & "_" & LCase(Replace(FORM.Capacity,".","_","ALL"));
	D.Config.Random=GetTickCount();
	D.Config.DEFAULTIMAGE=1;
	D.Config.FETCHINFO=1;
	D.Config.Found=0;
	D.Config.TextOverlay=1;
	D.Config.FontColor="##000000";
	D.Config.TextCSS="width:128px;font:30px Arial;color:##000000;text-indent:36px;padding-top:77px;height:113px;cursor:default;";
	D.Config.GoogleFont="";
	D.Config.TextFont="Arial";
	D.Config.DriveEdited=1;
	D.Config.TextBold=0;
	D.Config.TextItalics=0;
	D.Config.TextX=64;
	D.Config.TextY=86;
	D.Config.CenterX=1;
	D.Config.CenterY=1;
	D.Config.ImageHeight=175;
	D.Config.ImageWidth=128;
	D.Config.FontSize=30;
	D.Config.TextRotation=0;
	D.Attrib.Model=FORM.Model;
	D.Attrib.Vendor=FORM.Vendor;
	D.Attrib.Serial="No_" & ArrayLen(HW["Create"].Ports) + 1;
	D.Attrib.Rev=0;
	D.Attrib.Product=FORM.Model;
	D.Attrib.ro=0;
	D.Attrib.USB=0;
	D.Attrib.PlatterCnt=0;
	D.Attrib.HeadCnt=0;
	D.Attrib.Description="Manual Drive";
	D.Attrib.Configuration=StructNew();
	D.Attrib.Configuration.MultipleSectorTransfer=StructNew();
	D.Attrib.Configuration.MultipleSectorTransfer.Max=16;
	D.Attrib.Configuration.MultipleSectorTransfer.Current=16;
	D.Attrib.Configuration.LogicalSectorSize=512;
	D.Attrib.Configuration.SectorSize=512;
	D.Attrib.Configuration.SignalingSpeed=6;
	D.Attrib.Configuration.SignalingSpeedDisp="6Gbs";
	D.Attrib.Configuration.guid=CreateUUID();
	D.Attrib.Configuration.SectorOffset=0;
	D.Attrib.Configuration.RPM=7200;
	D.Attrib.Configuration.ANSIVersion=5;
	D.Attrib.Configuration.BlockCount=0;
	D.Attrib.Size=StructNew();
	D.Attrib.Size.DispSize=FORM.Capacity;
	D.Attrib.Size.Bytes=0;
	D.HDDBFound=1;
	</cfscript>
<CFELSE>
	<CFLOOP index="SKey" list="#StructKeyList(HW)#">
		<CFLOOP index="SPortNo" from="1" to="#ArrayLen(HW[SKey].Ports)#">
			<CFSET DriveID=HW[SKey].Ports[SPortNo].DriveID>
			<CFIF DriveID NEQ "">
				<CFIF HW[SKey].Ports[SPortNo].Attrib.Model EQ FORM.Clone>
					<cfscript>
					CloneKey=SKey;
					ClonePortNo=SPortNo;
					D=Duplicate(HW[SKey].Ports[SPortNo]);
					D.DevicePath="Phantom";
					D.ModelHash=CreateUUID();
					D.DriveHash=CreateUUID();
					D.DriveID="zz" & FormatBaseN(ArrayLen(HW.Create.Ports)+1,36);
					D.UNRAIDSlot="";
					D.OptimalBlockSize=33554432;
					D.Config.SaveDir=LCase(ModelDir) & "_" & LCase(Replace(FORM.Capacity,".","_","ALL"));
					D.Config.Random=GetTickCount();
					D.Config.DriveEdited=1;
					D.Attrib.Model=FORM.Model;
					D.Attrib.Vendor=FORM.Vendor;
					D.Attrib.Rev=0;
					D.Attrib.Product=FORM.Model;
					D.Attrib.ro=0;
					D.Attrib.Serial="No_" & ArrayLen(HW["Create"].Ports) + 1;
					D.Attrib.Size.DispSize=FORM.Capacity;
					</cfscript>
				</CFIF>
			</CFIF>
		</CFLOOP>
	</CFLOOP>
</CFIF>


<CFSET HW.Create.Ports[ArrayLen(HW.Create.Ports)+1]=Duplicate(D)>
<CFSET HW.Create.TotalDrives=ArrayLen(HW.Create.Ports)>

<!--- Rebuild quick reference --->
<CFINCLUDE TEMPLATE="BuildQuickRef.cfm">

<!--- Copy directories --->
<CFSET NewDir="#PersistDir#/driveinfo/" & LCase(ModelDir) & "_" & LCase(Replace(FORM.Capacity,".","_","ALL"))>
<CFIF DirectoryExists(NewDir) EQ "NO">
	<CFDIRECTORY action="create" directory="#NewDir#" mode="666">
</CFIF>
<CFIF FORM.Clone EQ "">
	<CFSET ConfigJSON='{"TEXTOVERLAY":"1","TEXTROTATION":"0","TEXTCSS":"width:128px;font:26px Arial;color:##ffffff;text-indent:33px;padding-top:139px;height:51px;cursor:default;","TEXTFONT":"Arial","TEXTBOLD":"0","TEXTY":"155","TEXTITALICS":"0","TEXTX":"64","CENTERY":"1","FONTCOLOR":"##ffffff","CENTERX":"1","FONTSIZE":"26"}'>
	<CFFILE action="write" file="#NewDir#/config.json" output="#ConfigJSON#" addnewline="NO" mode="666">
	<CFFILE action="copy" source="#RootDir#/images/default.png" destination="#NewDir#/image.png">
<CFELSE>
	<CFSET OldDir="#PersistDir#/driveinfo/" & HW[CloneKey].Ports[ClonePortNo].Config.SaveDir>
	<CFFILE action="copy" source="#OldDir#/config.json" destination="#NewDir#/config.json">
	<CFFILE action="copy" source="#OldDir#/image.png" destination="#NewDir#/image.png">
</CFIF>

<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">
<CFSET json=SerializeJSON(Ref)>
<CFFILE action="write" file="#PersistDir#/storageref.json" output="#json#" addnewline="NO" mode="666">

<cflock scope="Application" type="exclusive" timeout="30">
	<CFSET Application.AllModels="">
</cflock>

<CFLOCATION URL="index.cfm?DefaultVendor=#FORM.Vendor#&Clone=#FORM.Clone#&Capacity=#FORM.Capacity#" addtoken="NO">

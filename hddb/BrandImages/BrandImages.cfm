<CFSET IgnoreHash="1BB61EA7A634C9C9542F91195300338B">

<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" name="Vendors" type="Dir" sort="Name">

<CFPARAM name="URL.Vendor" default="#Vendors.Name[1]#">
<CFPARAM name="URL.Drive" default="">
<CFPARAM name="URL.dl" default="1">

<CFIF Find(".",URL.Vendor)>
	<CFABORT>
</CFIF>

<CFIF URL.Drive NEQ "">
	<CFTRY>
	<CFSET Img=Decrypt(URL.Drive,EncryptionKey,"AES","base64")>
	<CFSET ImgName=ListGetAt(Img,4,"/") & "." & ListLast(Img,".")>
	<CFIF FileExists("#ParentDir#/#Img#") EQ "NO">
		<CFABORT>
	</CFIF>
	<cfcontent reset="Yes">
	<CFIF Val(URL.dl) EQ 0>
		<cfheader name="cache-control" value="max-age=86400">
		<cfcontent type="image/png" file="#ParentDir#/#Img#" deletefile="NO">
	<CFELSE>
		<cfheader name="content-disposition" value="attachment; filename=""#ImgName#""">
		<cfcontent type="application/octet-stream" file="#ParentDir#/#Img#" deletefile="NO">
	</CFIF>
	<CFABORT>
	<CFCATCH Type="Any">
		<CFABORT>
	</CFCATCH>
	</CFTRY>

</CFIF>

<CFQUERY name="CheckVendor" dbtype="QUERY">
	SELECT *
	FROM Vendors
	WHERE Name='#URL.Vendor#'
</CFQUERY>
<CFIF CheckVendor.RecordCount EQ 0>
	<CFSET URL.Vendor=Vendors.Name[1]>
</CFIF>

<CFOUTPUT>
<table cellpadding="0" cellspacing="0" cellpadding="0">
	<tr>
		<td valign="top" class="NOBR" width="1">
			<!--- List Vendors --->
			<CFLOOP index="CR" from="1" to="#Vendors.RecordCount#">
				<CFSET TextColor=" White">
				<CFIF Vendors.Name[CR] EQ URL.Vendor>
					<CFSET TextColor=" Yellow">
				</CFIF>
				<CFIF Vendors.Name[CR] NEQ "Unknown">
					<a href="index.cfm?View=BrandImages&Vendor=#Vendors.Name[CR]#" class="Arial Bold TextBorder Size24 NoLink#TextColor#">#Vendors.Name[CR]#</a><br/>
				</CFIF>
			</CFLOOP>
		</td>
		<td width="1">&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td valign="top">
			<div id="TotalImg" class="Arial White Size24 TextBorder">&nbsp;</div>
			<br>
			<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives/#URL.Vendor#" name="PNG" type="file" sort="Directory,Name" filter="*.png" recurse="yes">
			<CFLOOP index="CR" from="1" to="#PNG.RecordCount#">
				<CFIF FileExists("#PNG.Directory[CR]#/#PNG.Name[CR]#.hash") EQ "NO">
					<CFFILE action="readbinary" file="#PNG.Directory[CR]#/#PNG.Name[CR]#" variable="bin">
					<CFSET BinHash=Hash(bin)>
					<CFFILE action="write" file="#PNG.Directory[CR]#/#PNG.Name[CR]#.hash" output="#BinHash#" addnewline="NO" mode="655">
					<CFSET fileSetAccessMode("#PNG.Directory[CR]#/#PNG.Name[CR]#.hash", "655")>
				</CFIF>
			</CFLOOP>
			<CFSET HashChk=ArrayNew(1)>
			<CFSET TotalImg=0>
			<CFLOOP index="CR" from="1" to="#PNG.RecordCount#">
				<CFFILE action="Read" file="#PNG.Directory[CR]#/#PNG.Name[CR]#.hash" variable="BinHash">
				<CFIF ArrayContainsNoCase(HashChk,BinHash) EQ 0 AND ListFindNoCase(IgnoreHash,BinHash) EQ 0>
					<CFSET HashChk[ArrayLen(HashChk)+1]=BinHash>
					<CFSET TotalImg=TotalImg + 1>
					<CFSET Path=Replace(Replace(PNG.Directory[CR],"\","/","ALL"),ParentDir,"")>
					<CFSET DLPath=URLEncodedFormat(Encrypt(Path & "/" & PNG.Name[CR],EncryptionKey,"AES","base64"))>
					<CFSET Path2=Replace(Path," ","%20","ALL")>
					<div class="ImgBox Margin20 Center FloatLeft NOBR Arial White Size14">
						<a href="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#&dl=1" class="NoLine"><img src="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#&dl=0"></a><br>
						#ListLast(Path,"/")#
					</div>
				</CFIF>
			</CFLOOP>
			<script>
			document.getElementById('TotalImg').innerHTML='<b>#TotalImg# model image<CFIF TotalImg NEQ 1>s</CFIF> found for #URL.Vendor#. Click <CFIF TotalImg NEQ 1>an<CFELSE>the</CFIF> image to download it.</b>';
			</script>

			<!---
			<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives/#URL.Vendor#" name="Models" type="Dir" sort="Name">
			<span class="Arial White Size18"><div id="Totals">&nbsp;</div></span>
			<CFSET Total=0>
			<CFLOOP index="CR" from="1" to="#Models.RecordCount#">
				<CFSET DriveDir=Replace(Models.Directory[CR]&"/"&Models.Name[CR],"\","/","ALL")>
				<CFDIRECTORY action="list" directory="#DriveDir#" name="AnyPNG" filter="*.png" type="file" sort="Name">
				<CFSET ModelHash=Hash(AnyPNG)>
				<CFIF FileExists("#DriveDir#/hash.txt")>
					<CFFILE action="read" file="#DriveDir#/hash.txt" variable="CacheHash">
				<CFELSE>
					<CFSET CacheHash="">
				</CFIF>
				<CFIF CashHash NEQ ModelHash>
					<CFSET PngData=ArrayNew(1)>
					<CFLOOP index="i" from="1" to="#AnyPNG.RecordCount#">
						<CFFILE action="readbinary" file="#DriveDir#/#AnyPNG.Name[i]#" variable="bin">
						<CFSET BinHash=Hash(bin)>
						<CFIF ArrayContainsNoCase(PngData,BinHash) EQ 0>
						</CFIF>
					</CFLOOP>
				</CFIF>
				<CFIF CashHash EQ ModelHash>
					<CFFILE action="read" file="#DriveDir#/dir.wddx" variable="DirWDDX">
					<cfwddx input="#DirWDDX#" output="PngData" action="wddx2cfml">
					<CFLOOP index="i" from="1" to="#ArrayLen(PngData)#">
						<CFSET Path=Replace(Replace(Models.Directory[CR],"\","/","ALL"),ParentDir,"") & "/" & ListLast(DriveDir,"/")>
						<CFSET DLPath=URLEncodedFormat(Encrypt(Path & "/" & PngData[i],EncryptionKey,"AES","base64"))>
						<CFSET Path2=Replace(Path," ","%20","ALL")>
						<div class="ImgBox Margin20 Center FloatLeft NOBR Arial White Size14">
							<!---<a href="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#" class="NoLine"><img src="#Path2#/#PngData[i]#"></a><br/>--->
							<a href="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#&dl=1" class="NoLine"><img src="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#&dl=0"></a><br/>
							#ListLast(DriveDir,"/")#
						</div>
					</CFLOOP>
				</CFIF>
				<!---
				<CFDIRECTORY action="list" directory="#DriveDir#" name="Drives" filter="Johnathan_Bartlett*.png" type="file">
				<CFIF Drives.RecordCount EQ 0>
					<CFIF FileExists("#DriveDir#/default.png")>
						<CFSET Img="default.png">
					<CFELSE>
						<CFDIRECTORY action="list" directory="#DriveDir#" name="AnyPNG" filter="*.png" type="file">
						<CFSET Img=AnyPNG.Name[1]>
					</CFIF>
				<CFELSE>
					<CFSET Img=Drives.Name>
				</CFIF>
				<CFSET Path=Replace(Replace(Models.Directory[CR],"\","/","ALL"),ParentDir,"") & "/" & ListLast(DriveDir,"/")>
				<CFSET DLPath=URLEncodedFormat(Encrypt(Path&"/"&Img,EncryptionKey,"AES","base64"))>
				<CFSET Path2=Replace(Path," ","%20","ALL")>
				<div class="ImgBox Margin20 Center FloatLeft NOBR Arial White Size14">
					<a href="index.cfm?View=BrandImages&Vendor=#URL.Vendor#&Drive=#DLPath#" class="NoLine"><img src="#Path2#/#Img#"></a><br/>
					#ListLast(DriveDir,"/")#
				</div>
				--->
			</CFLOOP>
				--->
		</td>
	</tr>
</table>
</CFOUTPUT>

<!--- #Models.RecordCount# drive image<CFIF Models.RecordCount NEQ 1>s</CFIF> found. Click to download.--->
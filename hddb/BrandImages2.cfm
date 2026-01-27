<CFParam name="URL.Vendor" default="">
<CFPARAM name="URL.Drive" default="">
<CFPARAM name="URL.dl" default="1">

<CFIF Find(".",URL.Vendor)>
	<CFABORT>
</CFIF>

<CFSET URL.Vendor=Replace(URL.Vendor,"x20"," ","ALL")>
<CFSET URL.Vendor=Replace(URL.Vendor,"x2D","-","ALL")>

<CFIF URL.Drive NEQ "">
	<CFTRY>
	<CFSET Img=Decrypt(URLDecode(URL.Drive),EncryptionKey,"AES","base64")>
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
	<CFCATCH Type="Any2">
		<CFABORT>
	</CFCATCH>
	</CFTRY>
</CFIF>



<!--- Load in TeleportHQ page --->
<CFFILE action="read" file="#RootDir#/Templates/brand-images-2.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">

<CFSET HTML=Replace(HTML,"background-color: var(--dl-color-gray-white);","")>


<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives" name="Vendors" type="Dir" sort="Name">

<CFQUERY name="CheckVendor" dbtype="QUERY">
	SELECT *
	FROM Vendors
	WHERE Name='#URL.Vendor#'
</CFQUERY>
<CFIF CheckVendor.RecordCount EQ 0>
	<CFSET URL.Vendor=Vendors.Name[1]>
</CFIF>

<!--- Drive Image Block --->
<CFSET ImgRegEx="<div id=""DriveImageBlock""[\w\d\s\W\D\S>]+?<\/span>\s+?<\/div>">

<!--- Check images for unprocessed --->
<CFDIRECTORY action="list" directory="#ParentDir#/diskspeed/Drives/#URL.Vendor#" name="PNG" type="file" sort="Directory,Name" filter="*.png" recurse="yes">
<CFLOOP index="CR" from="1" to="#PNG.RecordCount#">
	<CFIF FileExists("#PNG.Directory[CR]#/#PNG.Name[CR]#.hash") EQ "NO">
		<CFFILE action="readbinary" file="#PNG.Directory[CR]#/#PNG.Name[CR]#" variable="bin">
		<CFSET BinHash=Hash(bin)>
		<CFFILE action="write" file="#PNG.Directory[CR]#/#PNG.Name[CR]#.hash" output="#BinHash#" addnewline="NO" mode="655">
		<CFSET fileSetAccessMode("#PNG.Directory[CR]#/#PNG.Name[CR]#.hash", "655")>
	</CFIF>
</CFLOOP>

<CFSET Images="">
<CFSET HashChk=ArrayNew(1)>
<CFSET TotalImg=0>
<CFSET IgnoreHash="1BB61EA7A634C9C9542F91195300338B,ACAAD3CF3AF5CCDBEF0792BD41EF150A">
<CFSET IgnoreFN="Emil_Nilsson_0781_5580_0203_151038421814.png,Jake_Slominski_0781_5530_3110_830301727717.png,Marcus_Riedhammer_0781_5571_2113_112922054327.png," &
				"Trial_User_090C_1000_0000_490800000932.png,default.png,Tower_30DE_6544_BDFC_C731C324AA25.png,Jeroen_Westra_0781_5571_5508_102320135137.png," &
				"Patrick_Campos_Fischer_0781_5571_2029_021821080431.png,William_Martino_0930_6545_FCE8_B421396B1996.png,James_Osborn_0951_1665_B85E_DDA000000016.png," &
				"Caleb_Griffith_090C_1000_0340_523050001214.png,Philip_DeLeon_0781_5571_1001_630311112401.png,wyatt_christophers_0718_069C_0707_586FAF7F5C09.png," &
				"Henrik_E__0781_5583_8355_8107122A9DEB.png,Ian_Norman_07AB_FCF6_0000_900209272896.png,Chris_Cox_0781_5571_0001_140909104253.png,Ivan_Laptchenko_1B1C_1A06_0708_49B2041C4C05.png," &
				"Trial_User_1005_B155_0708_4C6DACC6A082.png,Alex_Wood_0951_1666_38F0_E761191201DE.png,Micael_Nystr_m_0781_5583_1001_500605118415.png,Rene_Palomino_0781_5583_8355_8107962E1C5B.png," &
				"Matt_Ward_13FE_3100_40E2_18003CF93246.png,Richard_Smith_0781_5583_8355_81077826A4C7.png,Eric_Bauer_0930_6545_7883_EE81D93EEE80.png,Blaine_Brodka_090C_1000_0309_221080006576.png," &
				"Trial_User_0781_5575_7618_101522154528.png,Danny_Martinez_0781_5571_0000_060819112412.png,Skynqiue_0781_5571_3526_090122082942.png,Christopher_Kliesch_0781_5591_9155_81071CB108C2.png," &
				"Skynqiue_0781_5571_3526_090122082942.png,Danny_Martinez_0781_5571_0000_060819112412.png,Jeff_Hynes_0781_5571_0000_250826110162.png,Bryan_Wall_0325_AC02_AA04_012700249298.png," &
				"Karsten_Isenberg_090C_1000_2010_091400004516.png,Skynqiue_0781_5571_3526_090122082942.png,Scott_Olson_090C_1000_0375_420040003253.png,Trial_User_18A5_0251_070C_3ACC30BE8C48.png," &
				"matteo_lacava_0781_5583_0000_130118223500.png,Scott_Reinlie_0781_5571_0001_281207103283.png,Bertram_Kantor_8564_1000_0000_00001I7D6S3V.png,Daniel_Hofmann_0B27_0916_0211_598776741947.png," &
				"gaming_0781_5583_0001_310910108335.png,JARED_VANORE_13FE_5200_070B_4879318A6E47.png,Brandon_Thivierge_0781_5571_0000_141017115290.png,Kim_Andre_Leonardsen_0781_5567_0000_120814110292.png," &
				"Trial_User_0781_5583_8355_81072E2949C8.png,aaron_werner_090C_1000_0327_722080000625.png,Scott_Reinlie_0781_5571_0001_281207103283.png,James_Bullard_090C_1000_0323_521070004786.png," &
				"Travis_Paulson_0781_5583_0001_170227101474.png,Trial_User_346D_5678_000F_C064D6B6D37A.png,Trial_User_0781_5571_0000_010523211371.png,Kevin_Bajohr_0781_5571_0000_050118215484.png," &
				"Trial_User_090C_1000_0364_621100003818.png,Real_Time_Computers_0930_6544_0549_C240893EE800.png,Akhil_Ashok_Kumar_0781_5567_0877_600A7A231592.png," &
				"Trial_User_0781_5583_8355_8107A1272082.png,Scott_Thompson_090C_1000_0361_123030003788.png,Brian_Smith_0951_1666_262E_F4B176062796.png,Corey_Kracht_0781_55A5_0000_080802121371.png" &
				"Ben_Guthrie_058F_6387_0000_0000MOG383ML.png,Hector_Rodriguez_Vargas_058F_6387_0000_0000AFF3DEF1.png,SUVOJIT_MAZUMDAR_0781_5567_4923_110723091124.png," &
				"Alex_English_0951_1666_74E4_F75089471E3E.png,Alex_Hand_13FE_3600_07A2_0500CF6353DC.png,Alex_Hand_13FE_3600_07A2_0500CF6353DC.png,Michael_Osmolski_21C4_0CD1_044R_AJ4BC4O3OKJA.png">

<CFLOOP index="CR" from="1" to="#PNG.RecordCount#">
	<CFFILE action="Read" file="#PNG.Directory[CR]#/#PNG.Name[CR]#.hash" variable="BinHash">
	<CFIF ArrayContainsNoCase(HashChk,BinHash) EQ 0 AND ListFindNoCase(IgnoreHash,BinHash) EQ 0 AND ListFindNoCase(IgnoreFN,PNG.Name[CR]) EQ 0>
		<CFSET HashChk[ArrayLen(HashChk)+1]=BinHash>
		<CFSET TotalImg=TotalImg + 1>
		<CFSET Path=Replace(Replace(PNG.Directory[CR],"\","/","ALL"),ParentDir,"")>
		<CFSET DLPath=URLEncodedFormat(Encrypt(Path & "/" & PNG.Name[CR],EncryptionKey,"AES","base64"))>
		<CFSET Path2=Replace(Path," ","%20","ALL")>
<CFSAVECONTENT variable="Images2">
<CFOUTPUT>
<div class="ModelBlock">
<center>
<a href="BrandImages2.cfm?Vendor=#EncodeForURL(URL.Vendor)#&Drive=#EncodeForURL(DLPath)#&dl=1">
<img
	alt="#EncodeForHTMLAttribute(ListLast(Path,"/"))#"
	src="BrandImages2.cfm?Vendor=#EncodeForURL(URL.Vendor)#&Drive=#EncodeForURL(DLPath)#&dl=0"
	loading="lazy"
	id="BrandImage"
	class="ModelImage"
/>
<span class="ModelText">
	#EncodeForHTML(ListLast(Path,"/"))#
</span>
</a>
</center>
</div>
</CFOUTPUT>
</CFSAVECONTENT>
		<CFSET Images=Images & Images2>
	</CFIF>
</CFLOOP>
<CFSET HTML=REReplaceNoCase(HTML,ImgRegEx,Images)>

<CFSET Vendor2="&nbsp;&nbsp;&nbsp;&nbsp;<small><small><small>#TotalImg# image">
<CFIF TotalImg NEQ 1>
	<CFSET Vendor2=Vendor2 & "s">
</CFIF>
<CFSET Vendor2=Vendor2 & " - click an image to download it</small></small></small>">
<CFSET HTML=Replace(HTML,"[Vendor]",EncodeForHTML(URL.Vendor) & Vendor2)>




<CFOUTPUT>#HTML#</CFOUTPUT>
UserIDSHA:
5ef44ee50cd1c5ecd4507412bfa20cea6446b37e
SerialHash:
5nyj
H:
055b2f0db29c2aef6ee037f0cdd6ed218767a32755028014e8a44a12ecc78b069846fde895e676df7102f62235e2fba82a7830516b1cfa0a917cac506732fb6c

========================================--------------------------------------------------------------------------------------------------------------------------------+xxxx
5ef44ee50cd1c5ecd4507412bfa20cea6446b37e055b2f0db29c2aef6ee037f0cdd6ed218767a32755028014e8a44a12ecc78b069846fde895e676df7102f62235e2fba82a7830516b1cfa0a917cac506732fb6c_5nyj
123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
         1         2         3         4         5         6         7         8         9         0         1         2         3         4         5         6         7         8

<CFPARAM name="URL.U" default="">

<CFSET UserIDSHA=Left(URL.U,40)>
<CFSET H=Mid(URL.U,41,128)>
<CFSET T=Val(Mid(URL.U,169,1))>
<CFSET SerialHash=Mid(URL.U,170,Len(URL.U))>

<!--- <cfoutput>
UserIDSHA #Len(UserIDSHA)#/40: #UserIDSHA#<br>
H #Len(H)#/128: #H#<br>
T #Len(T)#/1: #T#<br>
SerialHash #Len(SerialHash)#/#Len(SerialHash)/4#: #SerialHash#<br>
</cfoutput>
<cfabort> --->

<CFIF LCase(Hash(input="#UserIDSHA#|#SerialHash#",algorithm="SHA-512",numIterations = 10)) NEQ H>
	<CFABORT>
</CFIF>

<CFQUERY name="BenchUser" datasource="mysql">
	SELECT ID
	FROM DiskSpeed.Users
	WHERE SHA='#UserIDSHA#'
</CFQUERY>
<!--- <cfdump var=#BenchUser#> --->

<CFSET SerialIDList="">
<CFSET BenchHist=QueryNew("ID,UserID,DriveID,DateStamp,ModelID,RandomSeek,SequentialSeek,DriveLatency","integer,integer,varchar,time,bigint,bigint,bigint,bigint")>
<CFLOOP index="CurrSerial" from="1" to="#Len(SerialHash)#" step="4">
	<CFSET Serial=Mid(SerialHash,CurrSerial,4)>
	<!--- <CFOUTPUT>Importing #Serial#<br></CFOUTPUT> --->
	<CFQUERY name="Hist" datasource="mysql">
		SELECT *
		FROM DiskSpeed.BenchmarkID
		WHERE UserID=#Val(BenchUser.ID)#
		  AND DriveID='#Serial#'
		ORDER BY DateStamp DESC
		<CFIF T NEQ 0>
			LIMIT 0,#T#
		</CFIF>
	</CFQUERY>
	<CFQUERY name="tmp" dbtype="Query">
		SELECT * FROM BenchHist
		UNION
		SELECT * FROM Hist
	</CFQUERY>
	<CFSET BenchHist=Duplicate(tmp)>
</CFLOOP>

<CFSET BenchIDList="0">
<CFLOOP index="CR" from="1" to="#BenchHist.RecordCount#">
	<CFSET BenchIDList=ListAppend(BenchIDList,BenchHist.ID[CR])>
</CFLOOP>
<CFQUERY name="BenchData" datasource="mysql">
	SELECT BenchmarkID, Spot, Speed
	FROM DiskSpeed.Benchmarks
	WHERE BenchmarkID IN (#BenchIDList#)
</CFQUERY>

<!--- <cfdump var=#BenchHist#><cfdump var=#BenchData#> --->
<CFSET Out=StructNew()>
<CFSET Out['BenchHist']=Duplicate(BenchHist)>
<CFSET Out['BenchData']=Duplicate(BenchData)>
<!--- <cfdump var=#Out#> --->
<cfwddx input="#Out#" output="Out" action="cfml2wddx">

<CFOUTPUT>#Out#</CFOUTPUT>

<CFOUTPUT>
TRUNCATE TABLE DiskSpeed.PlatterInfo;<br>
insert into DiskSpeed.PlatterInfo (Vendor,Model,ShortStroked,Platters,Heads) VALUES <br>
</CFOUTPUT>
<CFFILE action="read" file="/tmp/DiskSpeed/Platters.txt" variable="data">
<CFLOOP index="Line" list="#data#" delimiters="#Chr(10)#">
	<CFSET CurrLine=Line>
	<CFIF Left(CurrLine,1) EQ "*">
		<CFSET Vendor=Trim(Mid(CurrLine,2,99))>
	</CFIF>
	<CFSET L1=ReFind("^\s{4}[\d\w\-\/]+",CurrLine)>
	<CFSET L2=ReFind("\s(\d+.\d+(GB|TB)|\d+(GB|TB))\s",CurrLine)>
	<CFSET L3=ReFind("\(\d+/\d+(| \[short-stroked\])\)",CurrLine)>
	<CFIF L1 GT 0 AND L2 GT 0 AND L3 GT 0>
		<CFSET Model=Trim(Left(Line,L2-1))>
		<CFIF ReFind("[a-z]",Model) EQ 0>
			<CFIF Find("[short-stroked]",CurrLine)>
				<CFSET ShortStroked=1>
				<CFSET CurrLine=ReplaceNoCase(CurrLine,"[short-stroked]","")>
			<CFELSE>
				<CFSET ShortStroked=0>
			</CFIF>
			<CFSET tmp=Trim(Mid(CurrLine,L3,Len(CurrLine)))>
			<CFSET tmp2=REMatchNoCase("\(\d+MB Cache\)",tmp)>
			<CFIF ArrayLen(tmp2) GT 0>
				<CFSET tmp=Replace(tmp,tmp2[1],"")>
			</CFIF>
			<CFSET Model=Replace(Model,"*","","ALL")>
			<CFIF Find("-",Model)>
				<CFSET Model=ListFirst(Model,"-")>
			</CFIF>
			<CFSET tmp=Replace(tmp,"*","","ALL")>
			<CFSET tmp=Replace(tmp,"?","","ALL")>
			<CFSET tmp=Replace(tmp,"(","","ALL")>
			<CFSET tmp=Replace(tmp,")","","ALL")>
			<CFSET tmp=Replace(tmp,".","","ALL")>
			<CFSET tmp=Replace(tmp," ","","ALL")>
			<CFSET PlatterCnt=ListFirst(tmp,"/")>
			<CFSET HeadCnt=ListLast(tmp,"/")>
			<CFIF ListLen(Model,"/") EQ 1>
				<CFOUTPUT>('#Vendor#','#Model#',#ShortStroked#,#PlatterCnt#,#HeadCnt#),<br></CFOUTPUT>
				<!---<CFOUTPUT>[#Line#] [#Vendor#][#Model#][#ShortStroked#][#PlatterCnt#][#HeadCnt#]<br></CFOUTPUT>--->
			<CFELSE>
				<CFIF Len(ListGetAt(Model,2,"/")) LTE 4>
					<!---<CFOUTPUT>[#Line#] [#Vendor#][#Model#][#ShortStroked#][#PlatterCnt#][#HeadCnt#]<br></CFOUTPUT>--->
					<CFOUTPUT>('#Vendor#','#Model#',#ShortStroked#,#PlatterCnt#,#HeadCnt#),<br></CFOUTPUT>
				<CFELSE>
					<CFLOOP index="i" from="1" to="#ListLen(Model,'/')#">
						<CFOUTPUT>('#Vendor#','#ListGetAt(Model,i,"/")#',#ShortStroked#,#PlatterCnt#,#HeadCnt#),<br></CFOUTPUT>
						<!---<CFOUTPUT>[#Line#] [#Vendor#][#ListGetAt(Model,i,"/")#][#ShortStroked#][#PlatterCnt#][#HeadCnt#]<br></CFOUTPUT>--->
					</CFLOOP>
				</CFIF>
			</CFIF>
			<CFIF IsNumeric(PlatterCnt) EQ "NO" OR IsNumeric(HeadCnt) EQ "NO">
				<CFOUTPUT>********<br></CFOUTPUT>
			</CFIF>
		</CFIF>
	</CFIF>
</CFLOOP>

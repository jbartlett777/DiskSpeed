<CFOUTPUT>
<font face="Arial" size="2">
<b>Error:</b> #CFCATCH.Message#<br>
<CFIF CFCATCH.Detail NEQ "">
	#CFCATCH.Detail#<br>
</CFIF>
<br>
</font>
<CFIF StructKeyExists(CFCATCH,"TagContext")>
	<CFLOOP index="i" from="1" to="#ArrayLen(CFCATCH.TagContext)#">
		<CFIF i EQ 1>
			<font face="Arial" size="2">
			<CFIF IsNumeric(CFCATCH.TagContext[i].Line) EQ "NO" AND FileExists(CFCATCH.TagContext[i].Template)>
				Unknown location<br>
			<CFELSE>
				The error occurred in #CFCATCH.TagContext[i].Template# on line #CFCATCH.TagContext[i].Line#<br><br>
				<font face="Courier New" size="2">
				<CFFILE action="read" file="#CFCATCH.TagContext[i].Template#" variable="Code">
				<CFSET Code=StripCR(Code)>
				<CFSET Start=CFCATCH.TagContext[i].Line - 2>
				<CFSET End=CFCATCH.TagContext[i].Line + 3>
				<CFIF Start LT 1>
					<CFSET Start=1>
				</CFIF>
				<CFIF End GT ListLen(Code,Chr(10))>
					<CFSET End=ListLen(Code,Chr(10))>
				</CFIF>
				<CFLOOP index="ln" from="#Start#" to="#End#">
					<CFSET Line=Replace(ListGetAt(Code,ln,Chr(10),"yes"),"<","&lt;","ALL")>
					<CFSET Line=Replace(Line,">","&gt;","ALL")>
					<CFSET Line=Replace(Line,Chr(9),"&nbsp;&nbsp;&nbsp;&nbsp;","ALL")>
					<CFIF ln EQ Start + 2>
						<b>#Replace(RJustify(LN,Len(End))," ","0","ALL")#: #Line#<br></b>
					<CFELSE>
						#Replace(RJustify(LN,Len(End))," ","0","ALL")#: #Line#<br>
					</CFIF>
				</CFLOOP>
			</CFIF>
			</font>
		<CFELSE>
		<br>
		Called from #CFCATCH.TagContext[i].Template#:#CFCATCH.TagContext[i].Line#<br>
		</CFIF>
	</CFLOOP>
	</font>
</CFIF>
<CFIF StructKeyExists(CFCATCH,"SQL")>
	<br>
	<b>SQL:</b><br>
	<CFSET SQL=Replace(CFCATCH.SQL,"<","&lt;","ALL")>
	<CFSET SQL=Replace(SQL,">","&gt;","ALL")>
	<CFSET SQL=Replace(SQL,Chr(9),"    ","ALL")>
	<CFSET SQL=Replace(SQL," ","&nbsp;","ALL")>
	<CFSET SQL=Replace(SQL,Chr(10),"<br>","ALL")>
	<font face="Courier New" size="2">#SQL#</font>
</CFIF>
</CFOUTPUT>
